_map = require 'lodash/map'
_filter = require 'lodash/filter'
_groupBy = require 'lodash/groupBy'
_some = require 'lodash/some'
_startCase = require 'lodash/startCase'
_uniq = require 'lodash/uniq'

Environment = require './environment'
DateService = require './date'
colors = require '../colors'
config = require '../config'

MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep',
          'oct', 'nov', 'dec']

console.log 'abcd'

class MapService
  hasLocationPermission: ({model} = {}) ->
    unless navigator?
      return Promise.resolve false

    # not available in native apps
    # https://stackoverflow.com/questions/52784495/is-there-any-alternative-to-navigator-permissions-query-permissions-api
    if model and Environment.isNativeApp('freeroam') and Environment.isAndroid()
      model.portal.call 'permissions.check', {
        permissions: [
          'android.permission.ACCESS_FINE_LOCATION'
          'android.permission.ACCESS_COARSE_LOCATION'
        ]
      }
      .then (results) ->
        results?['android.permission.ACCESS_FINE_LOCATION']
    else if navigator.permissions
      navigator.permissions.query {name: 'geolocation'}
      .then (permissionStatus) ->
        return permissionStatus.state is 'granted'
    else
      return Promise.resolve localStorage?.geolocationEnabled

  getLocation: ({model} = {}) ->
    get = =>
      new Promise (resolve, reject) =>
        if navigator?
          navigator.geolocation.getCurrentPosition (pos) ->
            localStorage?.geolocationEnabled = '1'
            lat = Math.round(10000 * pos.coords.latitude) / 10000
            lon = Math.round(10000 * pos.coords.longitude) / 10000
            resolve {lat, lon}
          , reject, {enableHighAccuracy: true, timeout: 10000}
        else
          resolve null

    isNativeApp = Environment.isNativeApp 'freeroam'
    isIos = Environment.isIos()
    isNativeIos = isNativeApp and isIos

    if model?.portal and not isNativeIos
      @hasLocationPermission {model}
      .then (hasPermission) ->
        if hasPermission
          get()
        else
          model.portal.call 'permissions.request', {
            permissions: [
              'android.permission.ACCESS_FINE_LOCATION'
              'android.permission.ACCESS_COARSE_LOCATION'
            ]
          }
          .catch (err) ->
            console.log 'perm req err', err
          .then get

    else
      get()

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
    # FIXME takes like a minute to load?
    # if Environment.isNativeApp 'freeroam'
    #   console.log 'getttt2' # FIXME FIXME: use fn here
    #   navigator.geolocation.getCurrentPosition onLocation, onError
    # else
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
        arrayValue: 'trash'
        name: model.l.get 'amenities.trash'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'recycle'
        name: model.l.get 'amenities.recycle'
      }
      {
        field: 'amenities'
        type: 'booleanArraySubTypes'
        items: [
          {key: 'anytime', label: model.l.get 'gyms.anytime'}
          {key: 'planet', label: model.l.get 'gyms.planet'}
        ]
        arrayValue: 'shower'
        name: model.l.get 'amenities.shower'
        valueFn: (value) ->
          _filter _map value, (subTypeValue, subTypeKey) ->
            if subTypeValue
              {match: subType: subTypeKey}
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'laundry'
        name: model.l.get 'amenities.laundry'
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
        arrayValue: 'water'
        name: model.l.get 'amenities.npwater'
      }
    ]

  getCampgroundFilters: ({model}) ->
    [
      {
        field: 'prices.all.mode'
        key: 'maxPrice'
        type: 'maxIntCustom'
        name: model.l.get 'campground.maxPrice'
      }
      {
        field: 'cellSignal'
        type: 'cellSignal'
        name: model.l.get 'campground.cellSignal'
      }
      {
        field: 'fullness'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.fullness'
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
        field: 'hookups'
        type: 'list'
        items: [
          {key: 'hasFreshWater', label: model.l.get 'filterDialog.hasFreshWater'}
          {key: 'hasSewage', label: model.l.get 'filterDialog.hasSewage'}
          {key: 'has30Amp', label: model.l.get 'filterDialog.has30Amp'}
          {key: 'has50Amp', label: model.l.get 'filterDialog.has50Amp'}
        ]
        name: model.l.get 'general.hookups'
      }
      {
        field: 'maxLength'
        key: 'minLength'
        type: 'minIntCustom'
        name: model.l.get 'campground.minLength'
      }
      {
        field: 'crowds'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.crowds'
      }
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: model.l.get 'campground.roadDifficulty'
      }
      {
        field: 'shade'
        type: 'maxInt'
        name: model.l.get 'campground.shade'
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
        field: 'attachmentCount'
        type: 'gtZero'
        isBoolean: true
        name: model.l.get 'campground.hasPhoto'
      }
    ]

  getHazardFilters: ({model}) ->
    [
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'wildfire'
        name: model.l.get 'hazard.wildfire'
      }
      {
        field: 'subType'
        type: 'maxClearance'
        name: model.l.get 'hazard.lowClearance'
        arrayValue: 'lowClearance'
        valueFn: (value) ->
          if value
            feet = parseInt value.feet
            if isNaN feet
              feet = 0
            inches = parseInt value.inches
            if isNaN inches
              feet = 0
            inches = feet * 12 + inches
            {range: 'data.heightInches': lte: inches}
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
        arrayValue: 'crackerBarrel'
        name: model.l.get 'overnight.crackerBarrel'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'other'
        name: model.l.get 'overnight.other'
      }
    ]

  getOptionalLayers: ({model, place, placePosition}) ->
    date = DateService.format new Date(), 'yyyy-mm-dd'

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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
        onclick: (e, properties) ->
          area = if properties.Loc_Nm \
                 then _startCase properties.Loc_Nm.toLowerCase()
                 else model.l.get 'general.unknown'
          access = if properties.Access \
                   then model.l.get "placeTooltip.pla.#{properties.Access}"
                   else model.l.get 'general.unknown'
          place.next {
            type: 'pad'
            location:
              lon: e.lngLat.lng
              lat: e.lngLat.lat
            name: 'BLM'
            description: """
Office: #{area}

Access: #{access}
            """
          }
          placePosition.next e.point
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
        onclick: (e, properties) ->
          area = if properties.Loc_Nm \
                 then _startCase properties.Loc_Nm.toLowerCase()
                 else model.l.get 'general.unknown'
          access = if properties.Access \
                   then model.l.get "placeTooltip.pla.#{properties.Access}"
                   else model.l.get 'general.unknown'
          place.next {
            type: 'pad'
            location:
              lon: e.lngLat.lng
              lat: e.lngLat.lat
            name: 'USFS'
            description: """
Forest: #{area}

Access: #{access}
            """
          }
          placePosition.next e.point
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
          metadata:
            zIndex: 2
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
          metadata:
            zIndex: 2
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
          metadata:
            zIndex: 2
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerSmoke'
        source:
          type: 'geojson'
          data: "#{config.MAPS_CDN_URL}/smoke.json?#{date}"
        layer:
          id: 'smoke'
          type: 'fill'
          source: 'smoke'
          layout: {}
          paint:
            'fill-opacity':
              property: 'Density',
              stops: [[0, 0], [100, 0.8]]
            'fill-color': colors.$grey700
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      {
        name: model.l.get 'placesMapContainer.layerFireWeather'
        source:
          type: 'geojson'
          data: "#{config.MAPS_CDN_URL}/fire_weather.json?#{date}"
        layer:
          id: 'fire-weather'
          type: 'fill'
          source: 'fire-weather'
          layout: {}
          paint:
            'fill-color': [
              'match'
              ['get', 'name']
              'Red Flag Warning', colors.$red500
              colors.$yellow500 # other
            ]
            'fill-opacity': 0.5
          metadata:
            zIndex: 2
        insertBeneathLabels: true
        onclick: (e, properties) ->
          place.next {
            name: properties.name
            description: properties.description
          }
          placePosition.next e.point
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
          metadata:
            zIndex: 1
        insertBeneathLabels: true
      }
    ]


  getESQueryFromFilters: (filters, currentMapBounds) =>
    groupedFilters = _groupBy filters, 'field'
    filter = _filter _map groupedFilters, (fieldFilters, field) =>
      unless _some fieldFilters, 'value'
        return

      filter = fieldFilters[0]

      switch filter.type
        when 'maxInt', 'maxIntCustom'
          {
            range:
              "#{field}":
                lte: filter.value
          }
        when 'minInt', 'minIntCustom'
          {
            range:
              "#{field}":
                gte: filter.value
          }
        when 'maxIntSeasonal'
          {
            range:
              "#{field}.#{filter.value.season}":
                lte: filter.value.value
          }
        # when 'maxClearance'
        #   feet = parseInt filter.value.feet
        #   if isNaN feet
        #     feet = 0
        #   inches = parseInt filter.value.inches
        #   if isNaN inches
        #     feet = 0
        #   inches = feet * 12 + inches
        #   {
        #     range:
        #       'data.heightInches':
        #         lt: inches
        #   }
        when 'maxIntDayNight'
          {
            range:
              "#{field}.#{filter.value.dayNight}":
                lte: filter.value.value
          }
        when 'gtZero'
          {
            range:
              "#{field}":
                gt: 0
          }
        when 'list'
          {
            bool:
              must: _filter _map filter.value, (value, key) ->
                if value
                  match: "#{key}": value
          }
        when 'cellSignal'
          carrier = filter.value.carrier
          if filter.value.isLte
            {
              range:
                "#{field}.#{carrier}_lte.signal":
                  gte: filter.value.signal
            }
          else
            # check for lte and non lte
            bool:
              should: [
                {
                  range:
                    "#{field}.#{carrier}.signal":
                      gte: filter.value.signal
                }
                {
                  range:
                    "#{field}.#{carrier}_lte.signal":
                      gte: filter.value.signal
                }
              ]
        when 'weather'
          if filter.value.month is 'forecast'
            {
              range:
                "forecast.#{filter.value.metric}":
                  "#{filter.value.operator}": parseFloat(filter.value.number)
            }
          else
            month = MONTHS[filter.value.month]
            {
              range:
                "#{field}.months.#{month}.#{filter.value.metric}":
                  "#{filter.value.operator}": parseFloat(filter.value.number)
            }
        when 'distanceTo'
          {
            range:
              "#{field}.#{filter.value.amenity}.time":
                lte: parseInt(filter.value.time)
          }
        when 'booleanArray'
          withValues = _filter(fieldFilters, 'value')

          {
            # there's potentially a cleaner way to do this?
            bool:
              should: _map withValues, ({value, arrayValue, valueFn}) ->
                # if subtypes are specified
                if typeof value is 'object'
                  bool:
                    must: [
                      {match: "#{field}": arrayValue}
                      bool:
                        should: valueFn value
                    ]
                else
                  {match: "#{field}": arrayValue}

            }

    filter.push {
      geo_bounding_box:
        location:
          top_left:
            lat: @formatLatitude currentMapBounds._ne.lat
            lon: @formatLongitude currentMapBounds._sw.lng
          bottom_right:
            lat: @formatLatitude currentMapBounds._sw.lat
            lon: @formatLongitude currentMapBounds._ne.lng
    }
    filter

  formatLatitude: (lat) ->
    lat = Math.round(1000 * lat) / 1000
    lat = Math.max -90, lat
    Math.min 90, lat

  formatLongitude: (lon) ->
    lon = Math.round(1000 * lon) / 1000
    lon = Math.max -180, lon
    Math.min 180, lon

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
