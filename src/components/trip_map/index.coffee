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
Fab = require '../fab'
Icon = require '../icon'
Tabs = require '../tabs'
TripItenerary = require '../trip_itenerary'
TravelMap = require '../travel_map'
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

module.exports = class TripMap
  constructor: ({@model, @router, @trip, checkIns}) ->
    @$travelMap = new TravelMap {
      @model, @router, @trip, checkIns
    }

    @state = z.state {
      @trip
      checkIns
    }

  share: =>
    @$travelMap.share()

  render: =>
    {trip, checkIns} = @state.getValue()

    z '.z-trip-map', {
      ontouchstart: (e) -> e.stopPropagation()
      onmousedown: (e) -> e.stopPropagation()
    },
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
