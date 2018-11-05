z = require 'zorium'
_map = require 'lodash/map'
_range = require 'lodash/range'
Environment = require '../../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
Textarea = require '../textarea'
Button = require '../flat_button'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

NPS_MIN = 0
NPS_MAX = 10
NPS_DEFAULT = 5
MIN_VISITS_TO_SHOW = 4

module.exports = class Nps
  constructor: ({@model}) ->
    @$dialog = new Dialog()

    @npsValue = new RxBehaviorSubject NPS_DEFAULT
    @commentValue = new RxBehaviorSubject ''
    # @emailValue = new RxBehaviorSubject ''

    @$commentInput = new Textarea
      value: @commentValue
    # @$emailInput = new Input
    #   value: @emailValue

    @$submitButton = new Button()
    @$cancelButton = new Button()

    @state = z.state
      npsValue: @npsValue
      commentValue: @commentValue
      # emailValue: @emailValue
      npsSet: false
      isLoading: false
      isVisible: localStorage? and not localStorage['hasGivenFeedback'] and
        not localStorage['hasSkippedFeedback'] and
        localStorage['visitCount'] >= MIN_VISITS_TO_SHOW
      step: 'prompt'

    if localStorage? and not localStorage?['visitCount']
      localStorage['visitCount'] = 1
    else if localStorage?
      localStorage['visitCount'] = parseInt(localStorage['visitCount']) + 1

  shouldBeShown: =>
    {isVisible} = @state.getValue()
    isVisible

  submitNps: =>
    {isLoading, npsValue, commentValue} = @state.getValue()

    if isLoading
      return

    unless npsValue >= 0 and npsValue <= 10
      return @npsError.next @model.l.get 'nps.num1to10'

    @state.set isLoading: true
    localStorage?['hasGivenFeedback'] = '1'

    @model.nps.create {
      score: npsValue
      comment: commentValue
    }
    .then =>
      @state.set isLoading: false

  render: ({onSubmit, onCancel, onRate}) =>
    {npsValue, isLoading, step} = @state.getValue()

    z '.z-nps',
      if step is 'prompt'
        z @$dialog,
          isVanilla: true
          $title: @model.l.get 'nps.title'
          $content:
            z '.z-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              @model.l.get 'nps.description'
          cancelButton:
            text: @model.l.get 'general.notNow'
            isShort: true
            onclick: =>
              localStorage?['hasSkippedFeedback'] = '1'
              @state.set isVisible: false
              onCancel?()

          submitButton:
            text: @model.l.get 'general.ok'
            isShort: true
            onclick: =>
              @state.set step: 'nps'
      else if step is 'rate'
        z @$dialog,
          isVanilla: true
          $title: @model.l.get 'nps.rate'
          $content:
            z '.z-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              z 'p', @model.l.get 'nps.thanks'
              z 'p', @model.l.get 'nps.appStore1'
              z 'p', @model.l.get 'nps.appStore2'
          cancelButton:
            text: @model.l.get 'general.notNow'
            isShort: true
            onclick: =>
              @state.set isVisible: false
              onCancel?()
          submitButton:
            text: @model.l.get 'nps.rate'
            isShort: true
            onclick: =>
              @state.set isVisible: false
              onRate()
      else
        z @$dialog,
          isVanilla: true
          title: ''
          $content:
            z '.z-nps_dialog', {
              style:
                maxWidth: "#{Math.min(240, window?.innerWidth - 64)}px"
            },
              z 'label.label',
                z '.text', @model.l.get 'nps.rate'
                z '.range-container',
                  z 'input.range',
                    type: 'range'
                    min: "#{NPS_MIN}"
                    max: "#{NPS_MAX}"
                    value: "#{npsValue}"
                    onchange: (e) =>
                      @npsValue.next e.currentTarget.value
                      @state.set npsSet: true
                z '.numbers',
                  _map _range(NPS_MIN, NPS_MAX + 1), (number) =>
                    z '.number', {
                      onclick: =>
                        @npsValue.next number
                        @state.set npsSet: true
                    },
                      number
              z 'label.label',
                # z '.text', 'Have any suggestions?'
                z @$commentInput,
                  hintText: @model.l.get 'nps.getComments'
                  isFloating: true

              # z 'label.label',
              #   z '.text', 'In case we need to follow up'
              #   z @$emailInput,
              #     hintText: 'Email address'
              #     colors:
              #       c500: colors.$grey900
          cancelButton:
            text: @model.l.get 'general.cancel'
            isShort: true
            onclick: =>
              localStorage?['hasSkippedFeedback'] = '1'
              @state.set isVisible: false
              onCancel?()
          submitButton:
            text: if isLoading \
                  then @model.l.get 'general.loading'
                  else @model.l.get 'general.submit'
            isShort: true
            onclick: =>
              @submitNps()
              isNativeApp = Environment.isNativeApp 'freeroam'
              if npsValue >= 8 and onRate and isNativeApp
                @state.set step: 'rate'
              else
                @state.set isVisible: false
              onSubmit?()
