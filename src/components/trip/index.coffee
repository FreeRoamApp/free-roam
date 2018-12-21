z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

AttachmentsList = require '../attachments_list'
Map = require '../map'
DateService = require '../../services/date'
FormatService = require '../../services/format'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTrip
  constructor: ({@model, @router, @trip}) ->
    checkIns = @trip.map (trip) ->
      trip?.checkIns
    # .publishReplay(1).refCount()
    route = checkIns.switchMap (checkIns) =>
      locations = _map checkIns, 'location'
      @model.trip.getRoute {checkIns}

    mapOptions = {
      @model, @router, places: checkIns, route: route
      initialBounds: [[-156.187, 18.440], [-38.766, 55.152]]
      # preserveDrawingBuffer: true
    }
    @$map = new Map mapOptions

    @state = z.state {
      trip: @trip
      route: route # TODO: rm from state, just send time
      checkIns: checkIns.map (checkIns) =>
        _map checkIns, (checkIn) =>
          {
            checkIn
            $attachmentsList: new AttachmentsList {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
            }
          }
    }

  render: =>
    {name, checkIns, trip, route} = @state.getValue()

    hasStats = Boolean route?.time

    z '.z-edit-trip', {
      className: z.classKebab {hasStats}
    },
      z '.map',
        z @$map
        z '.stats',
          z '.g-grid',
            z '.time',
              @model.l.get 'trip.totalTime'
              ": #{DateService.formatSeconds route?.time, 1}"
            z '.distance',
              @model.l.get 'trip.totalDistance'
              ": #{FormatService.number route?.distance}mi"
      z '.info',
        z '.g-grid',
          z '.check-ins',
            _map checkIns, ({checkIn, $attachmentsList}) ->
              z '.check-in', {
              },
                z '.info',
                  z '.name',
                    checkIn.name
                z '.attachments',
                  $attachmentsList
