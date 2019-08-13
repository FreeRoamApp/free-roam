z = require 'zorium'
_map = require 'lodash/map'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

PrimaryButton = require '../primary_button'
FlatButton = require '../flat_button'
SlideSteps = require '../slide_steps'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProductGuidesOnboard
  constructor: ({@model, @router, @isVisible}) ->
    @$slideSteps = new SlideSteps {@model}

    @$getStartedButton = new PrimaryButton()
    @$skipButton = new FlatButton()

    @rigTypeValueStreams = new RxReplaySubject 1
    @rigTypeValueStreams.next @model.userRig.getByMe().map (rig) ->
      rig?.type

    userData = @model.userData.getByMe()

    @experienceValueStreams = new RxReplaySubject 1
    @experienceValueStreams.next @model.userData.getByMe().map (userData) ->
      userData?.experience

    @hookupPreferenceValueStreams = new RxReplaySubject 1
    @hookupPreferenceValueStreams.next(
      @model.userData.getByMe().map (userData) ->
        userData?.hookupPreference
    )

    @state = z.state {
      step: 'intro'
      isVisible: true
      currentRigType: @rigTypeValueStreams.switch()
      currentExperience: @experienceValueStreams.switch()
      currentHookupPreference: @hookupPreferenceValueStreams.switch()
      isLoading: false
    }

  save: =>
    {step, isLoading, currentRigType, currentExperience,
      currentHookupPreference} = @state.getValue()

    if isLoading
      return

    @state.set isLoading: true

    Promise.all [
      @model.userData.upsert {
        experience: currentExperience
        hookupPreference: currentHookupPreference
      }
      @model.userRig.upsert {
        type: currentRigType
      }
    ]
    .then =>
      @state.set isLoading: false

  render: =>
    {step, isLoading, currentRigType, currentExperience,
      currentHookupPreference} = @state.getValue()

    z '.z-product-guides-onboard',
      if step is 'intro'
        z '.intro',
          z '.title', @model.l.get 'productGuidesOnboard.introTitle'
          z '.icon'
          z '.description', @model.l.get 'productGuidesOnboard.introDescription'
          z '.actions',
            z '.action',
              z @$getStartedButton,
                text: @model.l.get 'productGuidesOnboard.getStarted'
                onclick: =>
                  ga? 'send', 'event', 'guideOnboard', 'start', 'click'
                  @state.set step: 'steps'
            z '.action',
              z @$skipButton,
                text: @model.l.get 'general.noThanks'
                onclick: =>
                  ga? 'send', 'event', 'guideOnboard', 'noThanks', 'click'
                  @model.cookie.set 'hasSeenGuidesOnboard', '1'
                  @isVisible.next false
      else
        z @$slideSteps,
          onSkip: =>
            ga? 'send', 'event', 'guideOnboard', 'skip', 'click'
            @model.cookie.set 'hasSeenGuidesOnboard', '1'
            @isVisible.next false
          onDone: =>
            @save()
            .then =>
              ga?(
                'send', 'event', 'guideOnboard', 'done',
                "#{currentRigType},#{currentExperience},#{currentHookupPreference}"
              )
              @model.cookie.set 'hasSeenGuidesOnboard', '1'
              @isVisible.next false
          doneText: if isLoading \
                    then @model.l.get 'general.loading'
                    else @model.l.get 'general.finish'
          steps: [
            {
              $content:
                z '.z-product-guides-onboard_step',
                  z '.title', @model.l.get 'productGuidesOnboard.rigTitle'
                  z '.rig-types',
                    _map config.RIG_TYPES, (rigType) =>
                      z '.rig-type', {
                        className: z.classKebab {
                          isSelected: rigType is currentRigType
                        }
                        onclick: =>
                          ga? 'send', 'event', 'guideOnboard', 'rig', rigType
                          @rigTypeValueStreams.next RxObservable.of rigType
                      },
                        @model.l.get "rigs.#{rigType}"
            }
            {
              $content:
                z '.z-product-guides-onboard_step',
                  z '.title',
                    @model.l.get 'productGuidesOnboard.experienceTitle'
                  z '.buttons.g-grid',
                    z '.g-cols',
                      _map config.EXPERIENCE_TYPES, (experience) =>
                        z '.g-col.g-xs-6.g-md-6',
                          z '.button', {
                            className: z.classKebab {
                              isSelected: experience is currentExperience
                            }
                            onclick: =>
                              ga? 'send', 'event', 'guideOnboard', 'experience', experience
                              @experienceValueStreams.next(
                                RxObservable.of experience
                              )
                          },
                            @model.l.get(
                              "productGuidesOnboard.experience#{experience}"
                            )

            }
            {
              $content:
                z '.z-product-guides-onboard_step',
                  z '.title',
                    @model.l.get 'productGuidesOnboard.hookupPreferenceTitle'
                  z '.buttons.g-grid',
                    z '.g-cols',
                      _map config.HOOKUP_PREFERENCES, (hookupPreference) =>
                        z '.g-col.g-xs-6.g-md-6',
                          z '.button', {
                            className: z.classKebab {
                              isSelected:
                                hookupPreference is currentHookupPreference
                            }
                            onclick: =>
                              ga? 'send', 'event', 'guideOnboard', 'hookup', hookupPreference
                              @hookupPreferenceValueStreams.next(
                                RxObservable.of hookupPreference
                              )
                          },
                            @model.l.get(
                              "productGuidesOnboard.hookupPreference#{hookupPreference}"
                            )
            }
          ]
