z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_isEmpty = require 'lodash/isEmpty'
_omit = require 'lodash/omit'

Base = require '../base'
AttachmentsList = require '../attachments_list'
Fab = require '../fab'
Icon = require '../icon'
TravelMap = require '../travel_map'
CheckInTooltip = require '../check_in_tooltip'
DateService = require '../../services/date'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
# TODO: dialog after sharing asking people to leave reviews, give them list of ones they can add
###

module.exports = class Trip extends Base
  constructor: ({@model, @router, @trip}) ->
    @$addFab = new Fab()

    checkIns = @trip.map (trip) ->
      trip?.checkIns
    checkInsAndTrip = RxObservable.combineLatest(
      checkIns, @trip, (vals...) -> vals
    )


    @$travelMap = new TravelMap {
      @model, @router, @trip, checkIns
    }

    @state = z.state {
      me: @model.user.getMe()
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      checkIns: checkInsAndTrip.map ([checkIns, trip]) =>
        _map checkIns, (checkIn, i) =>
          if _isEmpty checkIn.attachments
            id = checkIn.id
          else
            id = _map(checkIn.attachments, 'id').join(',')
          $attachmentsList = @getCached$(
            "attachmentsList-#{id}", AttachmentsList, {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
            }
          )
          {
            checkIn
            routeInfo: if trip.route?.legs?[i]
              _omit trip.route.legs[i], ['shape']
            $attachmentsList: $attachmentsList
            $moreIcon: new Icon()
          }
    }

  share: =>
    ga? 'send', 'event', 'trip', 'share', 'click'
    @$travelMap.share()

  onReorder: (ids) =>
    ga? 'send', 'event', 'trip', 'reorder'
    {trip} = @state.getValue()
    @model.trip.upsert {
      id: trip.id
      checkInIds: ids
    }

  render: =>
    {me, name, checkIns, trip} = @state.getValue()

    hasEditPermission = @model.trip.hasEditPermission trip, me

    console.log checkIns

    z '.z-trip',
      z '.map',
        z @$travelMap
        if checkIns?.length > 1
          z '.places-along-route', {
            onclick: =>
              @router.go 'home', null, {
                qs:
                  tripId: trip.id
              }
          },
            @model.l.get 'trip.findAlongRoute'
      z '.info',
        z '.g-grid',
          if hasEditPermission
            z '.add', {
              onclick: =>
                @router.go 'newCheckIn', {
                  tripType: trip.type
                  tripId: trip.id
                }
            },
              z @$addFab,
                isSecondary: true
                icon: 'add'
                sizePx: 32
                onclick: =>
                  @router.go 'newCheckIn', {
                    tripType: trip.type
                    tripId: trip.id
                  }
              z '.text',
                @model.l.get 'trip.addLocation'
          z '.check-ins',
            [
              if _isEmpty checkIns
                z '.placeholder', @model.l.get 'trip.placeHolder'
              else
                z '.divider'
              _map checkIns, (checkIn, i) =>
                {checkIn, routeInfo,  $moreIcon, $attachmentsList} = checkIn

                location = @model.checkIn.getLocation checkIn

                z '.check-in.draggable', {
                  onclick: =>
                    @router.goOverlay 'checkIn', {
                      id: checkIn.id
                    }
                  attributes:
                    if @onReorder then {draggable: 'true'} else {}
                  dataset:
                    if @onReorder then {id: checkIn.id} else {}
                  ondragover: if @onReorder then z.ev (e, $$el) =>
                    @onDragOver e
                  ondragstart: if @onReorder then z.ev (e, $$el) =>
                    @onDragStart e
                  ondragend: if @onReorder then z.ev (e, $$el) =>
                    @onDragEnd e
                },
                  z '.time-wrapper',
                    z '.time',
                      z '.date',
                        if checkIn.startTime
                          DateService.format new Date(checkIn.startTime), 'MMM D'
                      if routeInfo
                        z '.travel-time',
                          z 'div',
                            "#{DateService.formatSeconds routeInfo?.time, 1} /"
                          z 'div',
                            "#{FormatService.number routeInfo?.distance}mi"


                  z '.dot'
                  z '.info',
                    z '.location',
                      "#{checkIns.length - i}. #{location}"
                    z '.name', @model.checkIn.getName checkIn
                    z '.attachments',
                      z $attachmentsList, {sizePx: 56}

                  z '.actions',
                    if checkIn.id
                      z $moreIcon,
                        icon: 'chevron-right'
                        isTouchTarget: false
                        color: colors.$secondary500

            ]

          z '.privacy', {
            onclick: =>
              @model.trip.upsert {
                id: trip.id
                privacy: if trip?.privacy is 'private' \
                         then 'public'
                         else 'private'
              }
          },
            "#{@model.l.get 'general.privacy'}: #{trip?.privacy or 'public'}"
