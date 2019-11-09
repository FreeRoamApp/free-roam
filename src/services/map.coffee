_clone = require 'lodash/clone'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_groupBy = require 'lodash/groupBy'
_orderBy = require 'lodash/orderBy'
_some = require 'lodash/some'
_startCase = require 'lodash/startCase'
_snakeCase = require 'lodash/snakeCase'
_uniq = require 'lodash/uniq'
_last = require 'lodash/last'

Environment = require './environment'
DateService = require './date'
colors = require '../colors'
config = require '../config'

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

  getLocation: ({model, timeout} = {}) ->
    timeout ?= 10000
    get = =>
      new Promise (resolve, reject) =>
        if navigator?
          navigator.geolocation.getCurrentPosition (pos) ->
            localStorage?.geolocationEnabled = '1'
            lat = Math.round(10000 * pos.coords.latitude) / 10000
            lon = Math.round(10000 * pos.coords.longitude) / 10000
            resolve {lat, lon}
          , reject, {enableHighAccuracy: true, timeout: timeout}
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

  getDirectionsBetweenPlaces: (places, {model}) ->
    places = _clone places
    target = '_system'
    baseUrl = 'https://google.com/maps/dir/?api=1'
    origin = places[0].location?.lat + ',' + places[0].location?.lon
    destination = _last(places).location?.lat + ',' + _last(places).location?.lon

    places.shift()
    places.pop()
    waypoints = _map(places, (place) ->
      "#{place.lat},#{place.lon}"
    ).join '|'

    url = "#{baseUrl}&origin=#{origin}&destination=#{destination}"
    if waypoints
      url += "&waypoints=#{waypoints}"
    model.portal.call 'browser.openWindow', {url, target}

  getDirections: (place, {model}) ->
    target = '_system'
    baseUrl = 'https://www.google.com/maps/dir/?api=1'
    destination = place?.location?.lat + ',' + place?.location?.lon

    isIos = Environment.isIos()

    onError = =>
      if isIos
        url = "#{baseUrl}&destination=#{destination}"
      else
        url = "#{baseUrl}&origin=My+Location&destination=#{destination}"
      model.portal.call 'browser.openWindow', {url, target}

    # FIXME takes like a minute to load?
    if Environment.isNativeApp 'freeroam'
      (if isIos
        # for some reason hasLocationPermission check not working on ios
        Promise.resolve true
      else
        @hasLocationPermission {model}
      ).then (hasLocationPermission) =>
        if hasLocationPermission
          @getLocation {model, timeout: 5000}
          .catch (err) ->
            console.log 'caught', err
            onError()
          .then ({lat, lon} = {}) ->
            if lat and lon
              origin = lat + ',' + lon
              url = "#{baseUrl}&origin=#{origin}&destination=#{destination}"
              model.portal.call 'browser.openWindow', {url, target}
        else
          onError()
    else
      console.log 'call onError'
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
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'water'
        name: model.l.get 'amenities.water'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'restArea'
        name: model.l.get 'overnight.restArea'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'groceries'
        name: model.l.get 'amenities.groceries'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'propane'
        name: model.l.get 'amenities.propane'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'trash'
        name: model.l.get 'amenities.trash'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'recycle'
        name: model.l.get 'amenities.recycle'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArraySubTypes'
        items: [
          {key: 'anytime', label: model.l.get 'gyms.anytime'}
          {key: 'planet', label: model.l.get 'gyms.planet'}
          {key: '24Hour', label: model.l.get 'gyms.24Hour'}
        ]
        arrayValue: 'shower'
        name: model.l.get 'amenities.shower'
        filterOverlayGroup: 'amenities'
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
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'gas'
        name: model.l.get 'amenities.gas'
        filterOverlayGroup: 'amenities'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'water'
        name: model.l.get 'amenities.npwater'
        filterOverlayGroup: 'amenities'
      }
    ]

  getCampgroundFilters: ({model}) ->
    [
      {
        field: 'subType'
        type: 'fieldList'
        items: [
          {key: 'public', label: model.l.get 'placeInfo.landTypePublic'}
          {key: 'private', label: model.l.get 'placeInfo.landTypePrivate'}
        ]
        name: model.l.get 'placeInfo.landType'
      }
      {
        field: 'prices.all.mode'
        key: 'maxPrice'
        type: 'maxIntCustom'
        inputPrefix: '$'
        name: model.l.get 'campground.maxPrice'
        title: model.l.get 'filterContent.title.maxPrice'
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
        filterOverlayGroup: 'sliders'
      }
      {
        field: 'weather'
        type: 'weather'
        name: model.l.get 'general.weather'
      }
      {
        field: 'distanceTo'
        type: 'distanceTo'
        name: model.l.get 'filterSheet.facilitiesNearby'
      }
      {
        field: 'features'
        type: 'iconListBooleanAnd'
        items: [
          {key: 'waterHookup', label: model.l.get 'feature.waterHookup'}
          {key: 'sewerHookup', label: model.l.get 'feature.sewerHookup'}
          {key: '30amp', label: model.l.get 'feature.30amp'}
          {key: '50amp', label: model.l.get 'feature.50amp'}
          {key: 'petsAllowed', label: model.l.get 'feature.petsAllowed'}
        ]
        name: model.l.get 'filterSheet.features'
      }
      {
        field: 'rating'
        type: 'reviews'
        name: model.l.get 'general.reviews'
      }
      {
        field: 'affiliations'
        type: 'listBooleanOr'
        items: [
          {key: 'escapees', label: model.l.get 'affiliation.escapees'}
          {key: 'goodSam', label: model.l.get 'affiliation.goodSam'}
          {
            key: 'passportAmerica'
            label: model.l.get 'affiliation.passportAmerica'
          }
        ]
        name: model.l.get 'general.affiliations'
      }
      {
        field: 'maxLength'
        key: 'minLength'
        type: 'minIntCustom'
        inputPostfix: 'ft'
        name: model.l.get 'campground.minLength'
      }
      {
        field: 'crowds'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.crowds'
        filterOverlayGroup: 'sliders'
      }
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: model.l.get 'campground.roadDifficulty'
        filterOverlayGroup: 'sliders'
      }
      {
        field: 'shade'
        type: 'maxInt'
        name: model.l.get 'campground.shade'
        filterOverlayGroup: 'sliders'
      }
      {
        field: 'safety'
        type: 'minInt'
        name: model.l.get 'campground.safety'
        filterOverlayGroup: 'sliders'
      }
      {
        field: 'noise'
        type: 'maxIntDayNight'
        name: model.l.get 'campground.noise'
        filterOverlayGroup: 'sliders'
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
        filterOverlayGroup: 'subType'
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

        filterOverlayGroup: 'lowClearance'
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
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'truckStop'
        name: model.l.get 'overnight.truckStop'
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'restArea'
        name: model.l.get 'overnight.restArea'
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'casino'
        name: model.l.get 'overnight.casino'
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'crackerBarrel'
        name: model.l.get 'overnight.crackerBarrel'
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'cabelas'
        name: model.l.get 'overnight.cabelas'
        filterOverlayGroup: 'overnights'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        isBoolean: true
        arrayValue: 'other'
        name: model.l.get 'overnight.other'
        filterOverlayGroup: 'overnights'
      }
    ]

  getOptionalLayers: ({model, place, placePosition}) ->
    date = DateService.format new Date(), 'yyyy-mm-dd'
    layerSettings = JSON.parse localStorage?.layerSettings or '{}'
    {
      'us-blm': {
        name: model.l.get 'placesMapContainer.layerBlm'
        thumb: "#{config.CDN_URL}/maps/blm_overlay.png"
        defaultOpacity: 0.5
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      'us-usfs': {
        name: model.l.get 'placesMapContainer.layerUsfs'
        thumb: "#{config.CDN_URL}/maps/usfs_overlay.png"
        defaultOpacity: 0.5
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      'us-cell-verizon': {
        name: model.l.get 'placesMapContainer.layerVerizonLte'
        thumb: "#{config.CDN_URL}/maps/verizon_overlay.png"
        defaultOpacity: 0.4
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      'us-cell-att': {
        name: model.l.get 'placesMapContainer.layerAttLte'
        thumb: "#{config.CDN_URL}/maps/att_overlay.png"
        defaultOpacity: 0.4
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      'us-cell-tmobile': {
        name: model.l.get 'placesMapContainer.layerTmobileLte'
        thumb: "#{config.CDN_URL}/maps/tmobile_overlay.png"
        defaultOpacity: 0.4
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      'us-cell-sprint': {
        name: model.l.get 'placesMapContainer.layerSprintLte'
        thumb: "#{config.CDN_URL}/maps/sprint_overlay.png"
        defaultOpacity: 0.4
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
          metadata:
            zIndex: 2
        insertBeneathLabels: true
      }

      smoke: {
        name: model.l.get 'placesMapContainer.layerSmoke'
        thumb: "#{config.CDN_URL}/maps/smoke_overlay.png"
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

      'fire-weather': {
        name: model.l.get 'placesMapContainer.layerFireWeather'
        thumb: "#{config.CDN_URL}/maps/fire_weather_overlay.png"
        defaultOpacity: 0.5
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

      satellite: {
        name: model.l.get 'placesMapContainer.layerSatellite'
        thumb: "#{config.CDN_URL}/maps/satellite_overlay.png"
        defaultOpacity: 1
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
          paint: {} # necessary to add opacity
          metadata:
            zIndex: 1
        insertBeneathLabels: true
      }
    }


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
        when 'listBooleanAnd', 'iconListBooleanAnd'
          {
            bool:
              must: _filter _map filter.value, (value, key) ->
                if value
                  match: "#{field}.#{key}": true
          }
        when 'listBooleanOr'
          {
            bool:
              should: _filter _map filter.value, (value, key) ->
                if value
                  match: "#{field}.#{key}": true
          }
        when 'fieldList'
          {
            bool:
              should: _filter _map filter.value, (value, key) ->
                if value
                  match: "#{field}": key
          }
        when 'reviews'
          {
            bool:
              must: _filter [
                if filter.value.rating
                  {range: {rating: {gte: filter.value.rating}}}
                if filter.value.hasPhotos
                  {range: {attachmentCount: {gt: 0}}}
              ]

          }
          # {
          #   field: 'attachmentCount'
          #   type: 'gtZero'
          #   isBoolean: true
          #   name: model.l.get 'campground.hasPhoto'
          # }
        when 'cellSignal'
          {
            bool:
              should: _map filter.value, (value, carrier) ->
                if carrier.indexOf('_lte') isnt -1
                  {
                    range:
                      "#{field}.#{carrier}.signal":
                        gte: value
                  }
                else
                  # check for lte and non lte
                  bool:
                    should: [
                      {
                        range:
                          "#{field}.#{carrier}.signal":
                            gte: value
                      }
                      {
                        range:
                          "#{field}.#{carrier.replace('_lte', '')}.signal":
                            gte: value
                      }
                    ]
          }
        when 'weather'
          if filter.value.month is 'forecast'
            bool:
              must: _map filter.value.metrics, ({operator, value}, metric) ->
                {
                  range:
                    "forecast.#{metric}":
                      "#{operator}": parseFloat(value)
                }
          else
            console.log filter.value.month, config.MONTHS[filter.value.month]
            month = config.MONTHS[filter.value.month]
            bool:
              must: _map filter.value.metrics, ({operator, value}, metric) ->
                range:
                  "#{field}.months.#{month}.#{metric}":
                    "#{operator}": parseFloat(value)
        when 'distanceTo'
          bool:
            must: _map filter.value.facilities, (facility) ->
              {
                range:
                  "#{field}.#{facility}.time":
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

    console.log 'filter', filter
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

  getIconByPlace: (place) =>
    switch place.type
      when 'overnight'
        @overnightIconGetFn(null) place
      when 'amenity'
        @amenityIconGetFn(null) place
      when 'hazard'
        @hazardIconGetFn(null) place
      when 'coordinate'
        'empty'
      else
        @campgroundIconGetFn(null) place

  campgroundIconGetFn: (filters) ->
    (campground) ->
      if campground?.prices?.all?.mode is 0 and campground?.ratingCount > 0
      then 'free'
      else if campground?.prices?.all?.mode is 0
      then 'free_reviewless'
      else if campground?.ratingCount > 0
      then 'paid'
      else 'paid_reviewless'

  overnightIconGetFn: (filters) ->
    (overnight) ->
      if overnight.subType in ['walmart', 'restArea', 'casino', 'truckStop', 'crackerBarrel', 'cabelas'] \
      then _snakeCase overnight.subType
      else 'default'

  amenityIconGetFn: (filters) ->
    filterValues = _map _filter(filters, 'value'), 'arrayValue'
    (amenity) ->
      icon = _orderBy(amenity.amenities, (amenity) ->
        filterValues.indexOf(amenity) isnt -1 and
          config.AMENITY_ICON_ORDER.indexOf(amenity)
      , ['desc'])[0]
      if icon is 'gym'
        icon = 'shower' # TODO: add gym icon, rm
      _snakeCase icon

  hazardIconGetFn: (filters) ->
    (hazard) ->
      _snakeCase hazard.subType

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
