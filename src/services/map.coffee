Environment = require './environment'
colors = require '../colors'

class MapService
  getDirections: (place, {model}) ->
    target = '_system'
    baseUrl = 'https://google.com/maps/dir/?api=1'
    destination = place?.location?.lat + ',' + place?.location?.lon
    onLocation = ({coords}) =>
      origin = coords?.latitude + ',' + coords?.longitude
      url = "#{baseUrl}&origin=#{origin}&destination=#{destination}"
      model.portal.call 'browser.openWindow', {url, target}
    onError = =>
      url = "#{baseUrl}&origin=My+Location&destination=#{destination}"
      model.portal.call 'browser.openWindow', {url, target}
    if Environment.isNativeApp 'freeroam'
      navigator.geolocation.getCurrentPosition onLocation, onError
    else
      console.log 'err'
      # just use the "my location" version, to avoid popup blocker
      onError()

  getAmenityFilters: ({model}) ->
    [
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'dump'
        name: model.l.get 'amenities.dump'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'water'
        name: model.l.get 'amenities.water'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'groceries'
        name: model.l.get 'amenities.groceries'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'propane'
        name: model.l.get 'amenities.propane'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'gas'
        name: model.l.get 'amenities.gas'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'trash'
        name: model.l.get 'amenities.trash'
      }
    ]

  getCampgroundFilters: ({model}) ->
    [
      {
        field: 'prices.all.mode'
        type: 'maxIntCustom'
        name: model.l.get 'campground.price'
      }
      {
        field: 'cellSignal'
        type: 'cellSignal'
        name: model.l.get 'campground.cellSignal'
      }
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: model.l.get 'campground.roadDifficulty'
      }
      {
        field: 'crowds'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.crowds'
      }
      {
        field: 'weather'
        type: 'weather'
        name: model.l.get 'general.weather'
      }
      {
        field: 'distanceTo'
        type: 'distanceTo'
        name: model.l.get 'campground.distanceTo'
      }
      {
        field: 'safety'
        type: 'minInt'
        name: model.l.get 'campground.safety'
      }
      {
        field: 'noise'
        type: 'maxIntDayNight'
        name: model.l.get 'campground.noise'
      }
      {
        field: 'fullness'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.fullness'
      }
      {
        field: 'shade'
        type: 'maxInt'
        name: model.l.get 'campground.shade'
      }
      {
        field: 'attachmentCount'
        type: 'gtZero'
        isBoolean: true
        name: model.l.get 'campground.hasPhoto'
      }
    ]

  getLowClearanceFilters: ({model}) ->
    [
      {
        field: 'heightInches'
        type: 'maxClearance'
        name: model.l.get 'lowClearance.maxClearance'
      }
    ]

  getOvernightFilters: ({model}) ->
    [
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'walmart'
        name: model.l.get 'overnight.walmart'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'truckStop'
        name: model.l.get 'overnight.truckStop'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'restArea'
        name: model.l.get 'overnight.restArea'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'casino'
        name: model.l.get 'overnight.casino'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'other'
        name: model.l.get 'overnight.other'
      }
    ]

  getOptionalLayers: ({model}) ->
    [
      {
        name: model.l.get 'placesMapContainer.layerBlm'
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
            # 'fill-color': colors.$mapLayerBlm
            'fill-pattern': 'blm_bg'
            'fill-opacity': 0.5
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerUsfs'
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
            # 'fill-color': colors.$mapLayerUsfs
            'fill-pattern': 'usfs_bg'
            'fill-opacity': 0.5
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerVerizonLte'
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
            # 'fill-color': colors.$verizon
            'fill-pattern': 'verizon_bg'
            'fill-opacity': 0.4
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerAttLte'
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
            # 'fill-color': colors.$att
            'fill-pattern': 'att_bg'
            'fill-opacity': 0.4
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerTmobileLte'
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
            # 'fill-color': colors.$tmobile
            'fill-pattern': 'tmobile_bg'
            'fill-opacity': 0.4
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerSprintLte'
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
            # 'fill-color': colors.$sprint
            'fill-pattern': 'sprint_bg'
            'fill-opacity': 0.4
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerSatellite'
        sourceId: 'mapbox'
        source:
          type: 'raster'
          url: 'mapbox://mapbox.satellite'
          tileSize: 256
        layer:
          id: 'satellite'
          type: 'raster'
          source: 'mapbox'
          'source-layer': 'mapbox_satellite_full'
        insertBeneathLabels: true
      }
    ]

  # This is adapted from the implementation in Project-OSRM
  # https://github.com/DennisOSRM/Project-OSRM-Web/blob/master/WebContent/routing/OSRM.RoutingGeometry.js

  decodePolyline: (str, precision = 6) ->
    index = 0
    lat = 0
    lng = 0
    coordinates = []
    shift = 0
    result = 0
    byte = null
    latitude_change = undefined
    longitude_change = undefined
    factor = 10 ** (precision)
    # Coordinates have variable length when encoded, so just keep
    # track of whether we've hit the end of the string. In each
    # loop iteration, a single coordinate is decoded.
    while index < str.length
      # Reset shift, result, and byte
      byte = null
      shift = 0
      result = 0
      loop
        byte = str.charCodeAt(index++) - 63
        result |= (byte & 0x1f) << shift
        shift += 5
        unless byte >= 0x20
          break
      latitude_change = if result & 1 then ~(result >> 1) else result >> 1
      shift = result = 0
      loop
        byte = str.charCodeAt(index++) - 63
        result |= (byte & 0x1f) << shift
        shift += 5
        unless byte >= 0x20
          break
      longitude_change = if result & 1 then ~(result >> 1) else result >> 1
      lat += latitude_change
      lng += longitude_change
      # mapbox likes these backwards
      coordinates.push [
        lng / factor
        lat / factor
      ]
    coordinates

module.exports = new MapService()
