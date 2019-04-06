z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_startCase = require 'lodash/startCase'
_camelCase = require 'lodash/camelCase'

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
    {@model, @router, isShell, type, subType,
      trip, mapBoundsStreams, searchQuery} = options

    @$addIcon = new Icon()

    @currentDataType = new RxReplaySubject 1
    if type
      @currentDataType.next type
    else
      @currentDataType.next RxObservable.of 'campground'

    typeAndSubType = RxObservable.combineLatest type, subType, (vals...) -> vals

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, isShell, trip
      persistentCookiePrefix: 'home'
      searchQuery
      mapBoundsStreams
      currentDataType: @currentDataType
      initialDataType: type # from url
      initialFilters: typeAndSubType.map ([type, subType]) ->
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
        }
        {
          dataType: 'overnight'
          filters: MapService.getOvernightFilters {@model}
          onclick: =>
            unless @model.cookie.get('hasSeenOvernightWarning')
              @model.cookie.set 'hasSeenOvernightWarning', '1'
              @model.overlay.open new OvernightWarningDialog {@model}
        }
        {
          dataType: 'amenity'
          filters: MapService.getAmenityFilters {@model}
        }
        {
          dataType: 'lowClearance'
          filters: MapService.getLowClearanceFilters {@model}
          onclick: =>
            unless @model.cookie.get('hasSeenLowClearanceWarning')
              @model.cookie.set 'hasSeenLowClearanceWarning', '1'
              @model.overlay.open new ClearanceWarningDialog {@model}
        }
      ]
      optionalLayers: MapService.getOptionalLayers {@model}
    }

    @state = z.state {
      currentDataType: @currentDataType.switch()
    }

  render: =>
    {currentDataType} = @state.getValue()

    z '.z-places',
      z @$placesMapContainer
