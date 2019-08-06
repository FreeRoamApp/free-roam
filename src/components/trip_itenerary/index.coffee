z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_clone = require 'lodash/clone'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_isEmpty = require 'lodash/isEmpty'
_omit = require 'lodash/omit'

Base = require '../base'
AttachmentsList = require '../attachments_list'
Icon = require '../icon'
CheckInTooltip = require '../check_in_tooltip'
DateService = require '../../services/date'
FormatService = require '../../services/format'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
# TODO: dialog after sharing asking people to leave reviews, give them list of ones they can add
###

module.exports = class TripItenerary extends Base
  constructor: ({@model, @router, @trip, checkIns}) ->
    checkInsAndTrip = RxObservable.combineLatest(
      checkIns, @trip, (vals...) -> vals
    )

    @state = z.state {
      me: @model.user.getMe()
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      checkIns: checkInsAndTrip.map ([checkIns, trip]) =>
        tripLegs = _clone(_map trip.route?.legs, (leg) ->
          _omit leg, ['shape']
        ).reverse()
        _map checkIns, (checkIn, i) =>
          if _isEmpty checkIn.attachments
            id = checkIn.id
          else
            id = _map(checkIn.attachments, 'id').join(',')
          $attachmentsList = @getCached$(
            "attachmentsList-#{id}", AttachmentsList, {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
              limit: 4
              more:
                if checkIn.attachments?.length > 4
                  {
                    onclick: =>
                      @router.goOverlay 'checkIn', {
                        id: checkIn.id
                      }
                    count: checkIn.attachments.length - 4
                  }
            }
          )
          {
            checkIn
            routeInfo: tripLegs?[i]
            $attachmentsList: $attachmentsList
            $roadIcon: new Icon()
          }
    }

  onReorder: (ids) =>
    ga? 'send', 'event', 'trip', 'reorder'
    {trip} = @state.getValue()
    @model.trip.upsert {
      id: trip.id
      checkInIds: _clone(ids).reverse()
    }

  render: =>
    {me, checkIns, trip} = @state.getValue()

    z '.z-trip-itenerary',
      z '.g-grid',
        z '.check-ins',
          [
            if _isEmpty checkIns
              z '.placeholder',
                z '.icon'
                z '.title', @model.l.get 'trip.placeHolderTitle'
                z '.description', @model.l.get 'trip.placeHolderDescription'
            else
              z '.divider'
            _map checkIns, (checkIn, i) =>
              {checkIn, routeInfo,  $roadIcon, $attachmentsList} = checkIn

              location = @model.checkIn.getLocation checkIn

              previousCheckIn = checkIns[i - 1]?.checkIn

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
                # ontouchstart: if @onReorder then z.ev (e, $$el) =>
                #   e.stopPropagation()
              },
                z '.dot'
                z '.info',
                  z '.dates',
                    z '.date',
                      if checkIn.startTime
                        DateService.format new Date(checkIn.startTime), 'MMM D'
                    if routeInfo
                      z '.travel-time', {
                        onclick: =>
                          console.log checkIn
                          MapService.getDirectionsBetweenPlaces(
                            previousCheckIn.place, checkIn.place, {@model}
                          )
                      },
                        z '.icon',
                          z $roadIcon,
                            icon: 'road'
                            isTouchTarget: false
                            size: '16px'
                            color: colors.$bgText54
                        "#{FormatService.number routeInfo?.distance}mi, "
                        "#{DateService.formatSeconds routeInfo?.time, 1}"

                  z '.location',
                    "#{checkIns.length - i}. #{location}"
                  z '.name', @model.checkIn.getName checkIn
                  z '.attachments',
                    z $attachmentsList, {sizePx: 56}
          ]

        z '.follow', {
          onclick: =>
            @model.tripFollower.upsertByTripId trip.id
        }, 'follow'

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
