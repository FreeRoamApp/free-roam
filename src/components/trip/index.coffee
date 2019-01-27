z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_omit = require 'lodash/omit'

AttachmentsList = require '../attachments_list'
Base = require '../base'
TravelMap = require '../travel_map'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Trip extends Base
  constructor: ({@model, @router, @trip}) ->
    checkIns = @trip.map (trip) ->
      trip?.checkIns
    # .publishReplay(1).refCount()
    @$travelMap = new TravelMap {
      @model, @router, @trip
    }

    @state = z.state {
      trip: @trip.map (trip) ->
        _omit trip, ['route']
      checkIns: checkIns.map (checkIns) =>
        _map checkIns, (checkIn) =>
          $attachmentsList = @getCached$(
            "attachmentsList-#{checkIn.id}", AttachmentsList, {
              @model, @router
              attachments: RxObservable.of checkIn.attachments
            }
          )
          {
            checkIn
            $attachmentsList
          }
    }

  render: =>
    {name, checkIns, trip} = @state.getValue()

    z '.z-edit-trip',
      z '.map',
        z @$travelMap
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
