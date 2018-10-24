z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Fab = require '../fab'
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
  constructor: ({@model, @router}) ->
    @$fab = new Fab()
    @$addIcon = new Icon()

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router
      persistentCookiePrefix: 'home'
      dataTypes: [
        {
          dataType: 'campground'
          filters: MapService.getCampgroundFilters {@model}
          defaultValue: true
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
        {
          dataType: 'overnight'
          filters: MapService.getOvernightFilters {@model}
          onclick: =>
            unless @model.cookie.get('hasSeenOvernightWarning')
              @model.cookie.set 'hasSeenOvernightWarning', '1'
              @model.overlay.open new OvernightWarningDialog {@model}
        }
      ]
      optionalLayers: [
        {
          name: @model.l.get 'placesMapContainer.layerBlm'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-blm.json'
          layer:
            id: 'us-blm'
            type: 'fill'
            source: 'us-blm'
            'source-layer': 'us_pad'
            layout: {}
            paint:
              'fill-color': colors.$mapLayerBlm
              'fill-opacity': 0.5
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerUsfs'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-usfs.json'
          layer:
            id: 'us-usfs'
            type: 'fill'
            source: 'us-usfs'
            'source-layer': 'us_pad'
            layout: {}
            paint:
              'fill-color': colors.$mapLayerUsfs
              'fill-opacity': 0.5
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerVerizonLte'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-cell-verizon.json'
          layer:
            id: 'us-cell-verizon'
            type: 'fill'
            source: 'us-cell-verizon'
            'source-layer': 'us_cell_verizon'
            layout: {}
            paint:
              'fill-color': colors.$verizon
              'fill-opacity': 0.3
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerAttLte'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-cell-att.json'
          layer:
            id: 'us-cell-att'
            type: 'fill'
            source: 'us-cell-att'
            'source-layer': 'us_cell_att'
            layout: {}
            paint:
              'fill-color': colors.$att
              'fill-opacity': 0.3
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerTmobileLte'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-cell-tmobile.json'
          layer:
            id: 'us-cell-tmobile'
            type: 'fill'
            source: 'us-cell-tmobile'
            'source-layer': 'us_cell_tmobile'
            layout: {}
            paint:
              'fill-color': colors.$tmobile
              'fill-opacity': 0.3
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerSprintLte'
          source:
            type: 'vector'
            url: 'https://tileserver.freeroam.app/data/free-roam-us-cell-sprint.json'
          layer:
            id: 'us-cell-sprint'
            type: 'fill'
            source: 'us-cell-sprint'
            'source-layer': 'us_cell_sprint'
            layout: {}
            paint:
              'fill-color': colors.$sprint
              'fill-opacity': 0.3
          insertBeneathLabels: true
        }
      ]
    }

    @state = z.state {}

  render: =>
    {} = @state.getValue()

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
            @router.go 'newCampground'
