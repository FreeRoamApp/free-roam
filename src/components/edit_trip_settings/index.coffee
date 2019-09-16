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

    @rigHeightFeetValueStreams = new RxReplaySubject 1
    @rigHeightFeetValueStreams.next (trip?.map (trip) ->
      trip.settings?.rigHeightInches ?= 13.5 * 12
      Math.floor(trip.settings?.rigHeightInches / 12)) or RxObservable.of 0
    @rigHeightFeetError = new RxBehaviorSubject null

    @$rigHeightFeetInput = new PrimaryInput
      valueStreams: @rigHeightFeetValueStreams
      error: @rigHeightFeetError

    @rigHeightInchesValueStreams = new RxReplaySubject 1
    @rigHeightInchesValueStreams.next (trip?.map (trip) ->
      trip.settings?.rigHeightInches ?= 13.5 * 12
      trip.settings?.rigHeightInches % 12) or RxObservable.of 0

    @rigHeightInchesError = new RxBehaviorSubject null

    @$rigHeightInchesInput = new PrimaryInput
      valueStreams: @rigHeightInchesValueStreams
      error: @rigHeightInchesError

    # feetValue = new RxBehaviorSubject @filter.value?.feet or '14'
    # @$feetInput = new PrimaryInput {value: feetValue}
    #
    # inchesValue = new RxBehaviorSubject @filter.value?.inches or '6'
    # @$inchesInput = new PrimaryInput {value: inchesValue}
    #
    # filterValue = RxObservable.combineLatest(
    #   feetValue
    #   inchesValue
    #   (vals...) -> vals
    # ).map ([feet, inches]) ->
    #   {feet, inches}

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

    @avoidHighwaysValueStreams = new RxReplaySubject 1
    @avoidHighwaysValueStreams.next (trip?.map (trip) ->
      trip.settings.avoidHighways) or RxObservable.of null

    @$avoidHighwaysToggle = new Toggle {
      isSelectedStreams: @avoidHighwaysValueStreams
    }

    @useTruckRouteValueStreams = new RxReplaySubject 1
    @useTruckRouteValueStreams.next (trip?.map (trip) ->
      trip.settings.useTruckRoute) or RxObservable.of null

    @$useTruckRouteToggle = new Toggle {
      isSelectedStreams: @useTruckRouteValueStreams
    }

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
      rigHeightFeet: @rigHeightFeetValueStreams.switch()
      rigHeightInches: @rigHeightInchesValueStreams.switch()
      isPrivate: @isPrivateValueStreams.switch()
      avoidHighways: @avoidHighwaysValueStreams.switch()
      useTruckRoute: @useTruckRouteValueStreams.switch()

  save: =>
    {trip, donutMin, donutMax, donutIsVisible, rigHeightFeet, rigHeightInches
      avoidHighways, useTruckRoute, isPrivate, isSaving} = @state.getValue()

    if isSaving
      return

    @state.set isSaving: true

    rigHeightInches = (rigHeightFeet * 12) + rigHeightInches

    @model.trip.upsert {
      id: trip.id
      settings:
        donut:
          min: donutMin
          max: donutMax
          isVisible: donutIsVisible
        rigHeightInches: rigHeightInches
        privacy: if isPrivate then 'private' else 'public'
        useTruckRoute: useTruckRoute
        avoidHighways: avoidHighways
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
            z '.extras',
              z '.short-input',
                z @$rigHeightFeetInput,
                  hintText: @model.l.get 'editTripSettings.rigHeightFeet'
                  type: 'number'
              z '.dash', @model.l.get 'editTripSettings.feetAbbr'
              z '.short-input',
                z @$rigHeightInchesInput,
                  hintText: @model.l.get 'editTripSettings.rigHeightInches'
                  type: 'number'
              z '.dash', @model.l.get 'editTripSettings.inchesAbbr'

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
            z '.title', @model.l.get 'editTripSettings.avoidHighways'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.avoidHighwaysDescription'
              z '.input',
                z @$avoidHighwaysToggle

          z '.field',
            z '.title', @model.l.get 'editTripSettings.useTruckRoute'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.useTruckRouteDescription'
              z '.input',
                z @$useTruckRouteToggle

          z '.field',
            z '.title', @model.l.get 'editTripSettings.privacy'
            z '.content',
              z '.description',
                @model.l.get 'editTripSettings.privacyDescription'
              z '.input',
                z @$isPrivateToggle
