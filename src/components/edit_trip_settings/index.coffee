z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/operator/switch'

ActionBar = require '../action_bar'
Toggle = require '../toggle'
PrimaryInput = require '../primary_input'
Icon = require '../icon'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripSettings
  constructor: ({@model, @router, trip}) ->
    @$actionBar = new ActionBar {@model}

    me = @model.user.getMe()

    @rigHeightValueStreams = new RxReplaySubject 1
    @rigHeightValueStreams.next (trip?.map (trip) ->
      trip.settings?.rigHeight) or RxObservable.of 0
    @rigHeightError = new RxBehaviorSubject null

    @$rigHeightInput = new PrimaryInput
      valueStreams: @rigHeightValueStreams
      error: @rigHeightError

    @donutIsVisibleValueStreams = new RxReplaySubject 1
    @donutIsVisibleValueStreams.next (trip?.map (trip) ->
      trip.settings.donut.isVisible) or RxObservable.of null

    @$donutIsVisibleToggle = new Toggle {
      isSelectedStreams: @donutIsVisibleValueStreams
    }

    @donutMinValueStreams = new RxReplaySubject 1
    @donutMinValueStreams.next (trip?.map (trip) ->
      trip.settings?.donut?.min) or RxObservable.of 0
    @donutMinError = new RxBehaviorSubject null

    @$donutMinInput = new PrimaryInput
      valueStreams: @donutMinValueStreams
      error: @donutMinError

    @donutMaxValueStreams = new RxReplaySubject 1
    @donutMaxValueStreams.next (trip?.map (trip) ->
      trip.settings?.donut?.max) or RxObservable.of 0
    @donutMaxError = new RxBehaviorSubject null

    @$donutMaxInput = new PrimaryInput
      valueStreams: @donutMaxValueStreams
      error: @donutMaxError

    @isPrivateValueStreams = new RxReplaySubject 1
    @isPrivateValueStreams.next (trip?.map (trip) ->
      trip.settings.privacy is 'private') or RxObservable.of null

    @$isPrivateToggle = new Toggle {isSelectedStreams: @isPrivateValueStreams}

    @state = z.state
      me: me
      trip: trip
      isSaving: false
      donutMin: @donutMinValueStreams.switch()
      donutMax: @donutMaxValueStreams.switch()
      donutIsVisible: @donutIsVisibleValueStreams.switch()
      rigHeight: @rigHeightValueStreams.switch()
      isPrivate: @isPrivateValueStreams.switch()

  save: =>
    {trip, donutMin, donutMax, donutIsVisible, rigHeight,
      isPrivate, isSaving} = @state.getValue()

    if isSaving
      return

    @state.set isSaving: true

    @model.trip.upsert {
      id: trip.id
      settings:
        donut:
          min: donutMin
          max: donutMax
          isVisible: donutIsVisible
        rigHeight: rigHeight
        privacy: if isPrivate then 'private' else 'public'
    }
    .then =>
      @state.set isSaving: false
      @router.back()

  render: =>
    {me, trip, isSaving, isPrivate} = @state.getValue()

    z '.z-edit-trip-settings',
      z @$actionBar, {
        isSaving: isSaving
        cancel:
          text: @model.l.get 'general.discard'
          onclick: =>
            @router.back()
        save:
          text: @model.l.get 'general.done'
          onclick: @save
      }
      z '.content',
        z '.g-grid',
          z '.field',
            z '.title', @model.l.get 'editTripSettings.rigHeight'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.rigHeightDescription'

          z '.field',
            z '.title', @model.l.get 'editTripSettings.mapDonut'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.mapDonutDescription'
              z '.input',
                z @$donutIsVisibleToggle
            z '.extras',
              z '.short-input',
                z @$donutMinInput,
                  hintText: @model.l.get 'editTripSettings.donutMin'
                  type: 'number'
                  isShort: true
              z '.dash', '-'
              z '.short-input',
                z @$donutMaxInput,
                  hintText: @model.l.get 'editTripSettings.donutMax'
                  type: 'number'
                  isShort: true

          z '.field',
            z '.title', @model.l.get 'editTripSettings.privacy'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.privacyDescription'
              z '.input',
                z @$isPrivateToggle
