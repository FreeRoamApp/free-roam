z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_startCase = require 'lodash/startCase'

Fab = require '../fab'
Icon = require '../icon'
ClearanceWarningDialog = require '../clearance_warning_dialog'
OvernightWarningDialog = require '../overnight_warning_dialog'
ReviewlessCampgroundWarningDialog = require '../reviewless_campground_warning_dialog'
PlacesMapContainer = require '../places_map_container'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Places
  constructor: ({@model, @router}) ->
    @$fab = new Fab()
    @$addIcon = new Icon()

    @currentDataType = new RxBehaviorSubject 'campground'

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router
      persistentCookiePrefix: 'home'
      currentDataType: @currentDataType
      dataTypes: [
        {
          dataType: 'campground'
          filters: MapService.getCampgroundFilters {@model}
          defaultValue: true
        }
        {
          dataType: 'reviewlessCampground'
          filters: MapService.getReviewlessCampgroundFilters {@model}
          onclick: =>
            unless @model.cookie.get('hasSeenReviewlessCampgroundWarning')
              @model.cookie.set 'hasSeenReviewlessCampgroundWarning', '1'
              @model.overlay.open new ReviewlessCampgroundWarningDialog {@model}
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

    @state = z.state {@currentDataType}

  render: =>
    {currentDataType} = @state.getValue()

    z '.z-places',
      z @$placesMapContainer

      z '.fab',
        z @$fab,
          colors:
            c500: colors.$tertiary100
            ripple: colors.$bgText70
          $icon: z @$addIcon, {
            icon: 'add'
            isTouchTarget: false
            color: colors.$bgText70
          }
          onclick: =>
            path = if currentDataType is 'overnight' \
                   then 'newOvernight'
                   else 'newCampground'
            @router.go path
