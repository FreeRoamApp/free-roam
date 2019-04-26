z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_find = require 'lodash/find'
_filter = require 'lodash/filter'

Icon = require '../icon'
TooltipPositioner = require '../tooltip_positioner'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceInfoActionBox
  constructor: ({@model, @router, @place}) ->
    @$directionsIcon = new Icon()
    @$shareIcon = new Icon()
    @$checkInIcon = new Icon()
    @$saveIcon = new Icon()
    # @$saveTooltip = new TooltipPositioner {
    #   @model
    #   key: 'saveLocation'
    #   anchor: 'top-right'
    #   zIndex: 999 # show for overlayPage
    #   offset:
    #     left: 32
    #     top: 16
    # }

    @checkInsStreams = new RxReplaySubject 1
    @resetValueStreams()
    checkIns = @checkInsStreams.switch()

    @state = z.state
      visitedSaving: false
      plannedSaving: false
      visitedCheckIn: checkIns.map (checkIns) ->
        _find(checkIns, {status: 'visited'}) or false
      plannedCheckIn: checkIns.map (checkIns) ->
        _find(checkIns, {status: 'planned'}) or false
      checkIns: checkIns
      place: @place

  resetValueStreams: =>
    checkInsAndPlace = RxObservable.combineLatest(
      @model.checkIn.getAll()
      @place
      (vals...) -> vals
    )

    @checkInsStreams.next checkInsAndPlace.map ([checkIns, place]) ->
      _filter checkIns, {sourceId: place?.id}

  beforeUnmount: =>
    @resetValueStreams()

  checkIn: (status) =>
    {place, checkIns} = @state.getValue()

    ga? 'send', 'event', 'placeInfo', 'checkIn', status

    @state.set "#{status}Saving": true
    checkIn = _find checkIns, {status}
    if checkIn
      @model.checkIn.deleteByRow {
        id: checkIn.id
      }
      .then (checkIn) =>
        @state.set "#{status}Saving": false
        @checkInsStreams.next RxObservable.of _filter checkIns, (checkIn) ->
          checkIn.status isnt status
    else
      @model.checkIn.upsert {
        name: place.name
        sourceType: place.type
        sourceId: place.id
        status: status
        setUserLocation: true
      }
      .then (checkIn) =>
        @state.set "#{status}Saving": false
        @checkInsStreams.next RxObservable.of checkIns.concat checkIn
        @model.statusBar.open {
          text: @model.l.get "placeInfo.#{status}Saved"
          type: 'snack'
          timeMs: 5000
          action:
            text: @model.l.get 'placeInfo.viewTrip'
            onclick: =>
              @router.go 'editTripByType', {
                type: if status is 'visited' then 'past' else 'future'
              }
              @model.statusBar.close()
        }

  render: =>
    {place, visitedCheckIn, plannedCheckIn, checkIns, visitedSaving,
      plannedSaving} = @state.getValue()

    z '.z-place-info-action-box',
      z '.actions',
        z '.action', {
          onclick: =>
            MapService.getDirections place, {@model}
        },
          z '.icon',
            z @$directionsIcon,
              icon: 'directions'
              isTouchTarget: false
              color: colors.$primary500
          z '.text', @model.l.get 'general.directions'

        z '.action', {
          onclick: =>
            ga? 'send', 'event', 'placeInfo', 'share'
            path = @model[place.type].getPath place, @router
            @model.portal.call 'share.any', {
              text: place.name
              path: path
              url: "https://#{config.HOST}#{path}"
            }
        },
          z '.icon',
            z @$shareIcon,
              icon: 'share'
              isTouchTarget: false
              color: colors.$primary500
          z '.text', @model.l.get 'general.share'

        if place?.type isnt 'amenity'
          [
            z '.action', {
              onclick: =>
                @checkIn 'visited'
            },
              z '.icon', {
                className: z.classKebab {
                  isFilled: visitedCheckIn
                }
              },
                z @$checkInIcon,
                  icon: 'location'
                  isTouchTarget: false
                  color: if visitedCheckIn \
                         then colors.$primary500Text
                         else colors.$primary500
              z '.text',
                if visitedSaving then @model.l.get 'general.saving'
                else if visitedCheckIn then @model.l.get 'placeInfo.checkedIn'
                else @model.l.get 'placeInfo.checkIn'
          ]
        z '.action', {
          onclick: => @checkIn 'planned'
        },
          z '.icon', {
            className: z.classKebab {
              isFilled: plannedCheckIn
            }
          },
            z @$saveIcon,
              icon: 'star'
              isTouchTarget: false
              color: if plannedCheckIn \
                     then colors.$primary500Text
                     else colors.$primary500
          z '.text',
            if plannedSaving then @model.l.get 'general.saving'
            else if plannedCheckIn then @model.l.get 'general.saved'
            else @model.l.get 'general.save'

          # A/B test with this on yielded ~10% increase in check-ins and
          # not statistical downside (other than for some reason less
          # trip events) but still not sure if it's worth hit
          # z @$saveTooltip
