z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_camelCase = require 'lodash/camelCase'
_startCase = require 'lodash/startCase'
_snakeCase = require 'lodash/snakeCase'
_orderBy = require 'lodash/orderBy'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Icon = require '../icon'
ClearanceWarningDialog = require '../clearance_warning_dialog'
OvernightWarningDialog = require '../overnight_warning_dialog'
PlacesMapContainer = require '../places_map_container'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Places
  constructor: (options) ->
    {@model, @router, isShell, type, subType, donut,
      trip, tripRoute, mapBoundsStreams, searchQuery} = options

    @currentDataType = new RxReplaySubject 1
    if type
      @currentDataType.next type
    else
      @currentDataType.next RxObservable.of 'campground'

    if type and subType
      typeAndSubType = RxObservable.combineLatest(
        type, subType, (vals...) -> vals
      )

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, isShell, trip, tripRoute
      persistentCookiePrefix: 'home'
      searchQuery
      mapBoundsStreams
      donut: donut
      currentDataType: @currentDataType
      initialDataType: type # from url
      initialFilters: typeAndSubType?.map ([type, subType]) ->
        if subType
          if type is 'amenity'
            {"#{type}.amenities.#{_camelCase subType}": true}
          else
            {"#{type}.subType.#{_camelCase subType}": true}
      dataTypes: [
        {
          dataType: 'campground'
          filters: MapService.getCampgroundFilters {@model}
          defaultValue: true
          getIconFn: MapService.campgroundIconGetFn
        }
        {
          dataType: 'overnight'
          filters: MapService.getOvernightFilters {@model}
          getIconFn: MapService.overnightIconGetFn
          onclick: =>
            unless @model.cookie.get('hasSeenOvernightWarning')
              @model.cookie.set 'hasSeenOvernightWarning', '1'
              @model.overlay.open new OvernightWarningDialog {@model}
        }
        {
          dataType: 'amenity'
          filters: MapService.getAmenityFilters {@model}
          getIconFn: MapService.amenityIconGetFn
        }
        {
          dataType: 'hazard'
          filters: MapService.getHazardFilters {@model}
          getIconFn: MapService.hazardIconGetFn
          onclick: =>
            unless @model.cookie.get('hasSeenLowClearanceWarning')
              @model.cookie.set 'hasSeenLowClearanceWarning', '1'
              @model.overlay.open new ClearanceWarningDialog {@model}
        }
      ]
    }

    @state = z.state {
      currentDataType: @currentDataType.switch()
    }

  render: =>
    {currentDataType} = @state.getValue()

    z '.z-places',
      z @$placesMapContainer
