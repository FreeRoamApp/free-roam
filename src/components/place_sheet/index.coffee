z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
_kebabCase = require 'lodash/kebabCase'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
Rating = require '../rating'
Toggle = require '../toggle'
CoordinateInfoDialog = require '../coordinate_info_dialog'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceSheet
  constructor: (options) ->
    {@model, @router, @place, @trip, @tripRoute, @layersVisible,
      @addOptionalLayer, @addLayerById, @removeLayerById} = options

    @$directionsIcon = new Icon()
    @$addCampsiteIcon = new Icon()
    @$saveIcon = new Icon()
    @$infoIcon = new Icon()

    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }

    sheetData = RxObservable.combineLatest(
      @place or RxObservable.of null
      @trip or RxObservable.of null
      @tripRoute or RxObservable.of null
    )

    @state = z.state {
      @place
      @trip
      isLoadingButtons: []
      isLoadedButtons: []
      info: sheetData.switchMap ([place, trip, tripRoute]) =>
        if place?.type
          # @model.geocoder.getCoordinateInfoFromLocation place.location
          @model.placeBase.getSheetInfo {
            place, tripId: trip?.id, tripRouteId: tripRoute?.id
          }
          .map (info) =>
            _defaults {
              localMaps: _map info?.localMaps, (localMap) =>
                isSelectedStreams = new RxReplaySubject 1
                isSelectedStreams.next @layersVisible.map (layersVisible) ->
                  layersVisible.indexOf(localMap.slug) isnt -1
                {
                  localMap
                  isSelectedStreams
                  $toggle: new Toggle {
                    isSelectedStreams
                  }
                }
            }, info
        else
          RxObservable.of false
      buttons: sheetData.map ([place, trip, tripRoute]) =>
        _filter [
          if tripRoute?.id
            {
              $icon: new Icon()
              icon: 'add'
              text: @model.l.get 'placeSheet.addStop'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                @saveCheckIn()
                .then (checkIn) =>
                  @model.trip.upsertStopByIdAndRouteId(
                    trip?.id
                    tripRoute?.id
                    checkIn
                  )
            }
          else if trip?.id
            {
              $icon: new Icon()
              icon: 'add'
              text: @model.l.get 'placeSheet.addToTrip'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                @saveCheckIn()
                .then (checkIn) =>
                  @model.trip.upsertDestinationById(
                    trip?.id
                    checkIn
                  )
            }
          if place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'directions'
              text: @model.l.get 'general.directions'
              onclick: =>
                MapService.getDirections {
                  location:
                    lat: place.location[1]
                    lon: place.location[0]
                }, {@model}
            }
          if place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'star'
              text: @model.l.get 'general.save'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: @saveCheckIn
            }
          if place?.type isnt 'coordinate' or not _isEmpty place?.features
            {
              $icon: new Icon()
              icon: 'info'
              text: @model.l.get 'general.info'
              onclick: =>
                if place?.type is 'coordinate'
                  @model.overlay.open new CoordinateInfoDialog {
                    @model, @router, coordinate: place, @addOptionalLayer
                    @addLayerById, @removeLayerById, @layersVisible
                  }
                else
                  @router.goOverlay place.type, {slug: place.slug}
                Promise.resolve null
            }
          if place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'add-circle'
              text: @model.l.get 'coordinateTooltip.addCampsite'
              onclick: =>
                @router.go 'newCampground', {}, {
                  qs:
                    location: Math.round(place.location[1] * 1000) / 1000 +
                              ',' +
                              Math.round(place.location[0] * 1000) / 1000
                }
                Promise.resolve null
            }
        ]
    }

  beforeUnmount: =>
    @state.set isLoadedButtons: [], isLoadingButtons: []

  saveCheckIn: =>
    {place} = @state.getValue()

    if place.type is 'coordinate'
      name = prompt 'Enter a name'
      @model.coordinate.upsert {
        name: name
        location: place.location
      }, {invalidateAll: false}
      .then ({id}) =>
        @model.checkIn.upsert {
          sourceType: 'coordinate'
          sourceId: id
          status: 'planned'
        }
    else
      @model.checkIn.upsert {
        name: place.name
        sourceType: place.type
        sourceId: place.id
        status: 'planned'
        setUserLocation: false
      }

  render: ({isVisible} = {}) =>
    {place, trip, buttons, info,
      isLoadingButtons, isLoadedButtons, elevation} = @state.getValue()

    console.log 'sheet place', info

    isVisible ?= Boolean place

    {elevation, localMaps} = info or {}

    if not elevation? or elevation is false
      elevation = '...'

    isDisabled = not place or not (place.type in [
      'campground', 'overnight', 'amenity'
    ])

    z 'a.z-place-sheet', {
      className: z.classKebab {isVisible}
      href: @router.get place?.type, {slug: place?.slug}
      onclick: (e) =>
        e?.stopPropagation()
        if place?.type is 'hazard' and place?.subType is 'lowClearance'
          [lon, lat] = place.location
          @model.portal.call 'browser.openWindow', {
            url:
              "https://maps.google.com/maps?z=18&t=k&ll=#{lat},#{lon}"
          }
        else if not isDisabled
          e?.preventDefault()
          @router.goOverlay place.type, {slug: place.slug}
    },
      z '.sheet',
        z '.content',
          z '.left',
            z '.title', place?.name

            if place?.type is 'coordinate'
              z '.elevation',
                @model.l.get 'coordinateTooltip.elevation', {replacements: {elevation}}

            if info?.addStopInfo
              z '.add-stop-info',
                z '.from-last-stop',
                  @model.l.get 'placeSheet.fromLastStop', {
                    replacements:
                      time: Math.round(info.addStopInfo.fromLastStop.time / 60)
                      distance: Math.round(
                        10 * info.addStopInfo.fromLastStop.distance
                      ) / 10
                  }
                if info.addStopInfo.detourTime?
                  z '.detour',
                    @model.l.get 'placeSheet.detour', {
                      replacements:
                        time: Math.round(info.addStopInfo.detourTime / 60)
                    }

          z '.right',
            if place?.type and not (place?.type in ['hazard', 'blm', 'usfs'])
              [
                z '.rating',
                  z @$rating, {size: '16px', color: colors.$secondary500}
                z '.rating-text',
                  if place?.rating
                    "#{place?.rating.toFixed(1)}"
                  z 'span.rating-count',
                    ' ('
                    @model.l.get 'place.reviewCount', {
                      replacements:
                        count: place?.ratingCount or 0
                    }
                    ')'
              ]



        z '.buttons',
          _map buttons, (button, i) =>
            isLoading = isLoadingButtons.indexOf(i) isnt -1
            isLoaded = isLoadedButtons.indexOf(i) isnt -1
            z '.button', {
              onclick: (e) =>
                e?.stopPropagation()
                e?.preventDefault()
                @state.set isLoadingButtons: [i]
                button.onclick e
                .then =>
                  @state.set isLoadingButtons: [], isLoadedButtons: [i]
                  setTimeout =>
                    @state.set isLoadedButtons: []
                  , 1000
            },
              z '.icon',
                z button.$icon,
                  icon: button.icon
                  size: '18px'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                if isLoading and button.loadingText
                then button.loadingText
                else if isLoaded and button.loadedText
                then button.loadedText
                else button.text

        unless _isEmpty localMaps
          z '.local-maps',
            _map localMaps, ({localMap, isSelectedStreams, $toggle}) =>
              z '.local-map',
                'MVUM: ' + localMap.name
                z '.toggle',
                  z $toggle, {
                    onToggle: (isSelected) =>
                      if isSelected
                        @addOptionalLayer {
                          isTemporary: true
                          name: localMap.name
                          defaultOpacity: 0.8
                          source:
                            type: 'raster'
                            url: "https://localmaps.freeroam.app/data/#{localMap.slug}.json"
                            tileSize: 256 # built as 512 block size, rendered as this for crisper look
                          layer:
                            id: localMap.slug
                            type: 'raster'
                            source: localMap.slug
                            paint: {}
                            metadata:
                              zIndex: 2
                        }
                        @addLayerById localMap.slug
                      else
                        @removeLayerById localMap.slug

                      # reset to main stream in case value changes elsewhere
                      isSelectedStreams.next @layersVisible.map (layersVisible) ->
                        layersVisible.indexOf(localMap.slug) isnt -1

                  }
