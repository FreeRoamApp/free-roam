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
_find = require 'lodash/find'
_defaults = require 'lodash/defaults'

Base = require '../base'
Icon = require '../icon'
Rating = require '../rating'
Toggle = require '../toggle'
AddPlaceDialog = require '../add_place_dialog'
CoordinateInfoDialog = require '../coordinate_info_dialog'
NewCheckIn = require '../new_check_in'
DateService = require '../../services/date'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceSheet extends Base
  constructor: (options) ->
    {@model, @router, @place, trip, tripRoute, isEditingRoute,
      editRouteWaypointsStreams, @layersVisible,
      @addOptionalLayer, @addLayerById, @removeLayerById} = options

    @$directionsIcon = new Icon()
    @$addPlaceIcon = new Icon()
    @$saveIcon = new Icon()
    @$infoIcon = new Icon()

    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }

    sheetData = RxObservable.combineLatest(
      @place or RxObservable.of null
      @model.checkIn.getAll()
      trip or RxObservable.of null
      tripRoute or RxObservable.of null
      isEditingRoute or RxObservable.of null
      editRouteWaypointsStreams?.switch() or RxObservable.of null
    )

    @state = z.state {
      @place
      trip
      isEditingRoute
      isLoadingButtons: []
      isLoadedButtons: []
      info: sheetData.switchMap (data) =>
        [place, checkIns, trip, tripRoute, isEditingRoute] = data
        if place?.type and not isEditingRoute
          # @model.geocoder.getCoordinateInfoFromLocation place.location
          @model.placeBase.getSheetInfo {
            place, tripId: trip?.id, tripRouteId: tripRoute?.routeId
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
      buttons: sheetData.map (data) =>
        [place, checkIns, trip, tripRoute, isEditingRoute, waypoints] = data
        isSaved = place and checkIns and _find(checkIns, {
          status: 'planned', sourceId: place.id
        }) or false


        _filter [
          if isEditingRoute and place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'add'
              text: @model.l.get 'placeSheet.routeThroughHere'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                editRouteWaypointsStreams.next(
                  RxObservable.of (waypoints or []).concat [place.location]
                )
                @place.next null
                Promise.resolve null
            }
          else if isEditingRoute and place?.type is 'waypoint'
            {
              $icon: new Icon()
              icon: 'add'
              text: @model.l.get 'placeSheet.removeFromRoute'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                wp = waypoints
                index = parseInt(place.name.match(/\((.*)\)/)?[1])
                wp.splice wp.length - index, 1
                editRouteWaypointsStreams.next RxObservable.of wp
                @place.next null
                Promise.resolve null
            }
          else if tripRoute?.routeId and place?.hasDot
            {
              $icon: new Icon()
              icon: 'subtract-circle'
              text: @model.l.get 'placeSheet.removeStop'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                @model.trip.deleteStopByIdAndRouteId(
                  trip.id
                  tripRoute.routeId
                  place
                )
            }
          else if tripRoute?.routeId
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
                    tripRoute?.routeId
                    checkIn
                  )
            }
          else if trip?.id and place?.number
            {
              $icon: new Icon()
              icon: 'subtract-circle'
              text: @model.l.get 'placeSheet.removeFromTrip'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                @model.trip.deleteDestinationById trip.id, place.checkInId
            }
          else if trip?.id
            {
              $icon: new Icon()
              icon: 'add'
              text: @model.l.get 'placeSheet.addToTrip'
              loadingText: @model.l.get 'general.saving'
              loadedText: @model.l.get 'general.saved'
              onclick: =>
                @model.overlay.open new NewCheckIn {
                  @model, @router, @place, isOverlay: true
                  trip: RxObservable.of(trip), skipChooseTrip: true
                }
                Promise.resolve true
            }
          if trip?.id and place?.number
            {
              $icon: new Icon()
              icon: 'edit'
              text: @model.l.get 'general.edit'
              # loadingText: @model.l.get 'general.saving'
              # loadedText: @model.l.get 'general.saved'
              onclick: =>
                @router.goOverlay 'editCheckIn', {id: place.checkInId}
            }
          if place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'directions'
              text: @model.l.get 'general.directions'
              onclick: =>
                MapService.getDirections {
                  location: place.location
                }, {@model}
            }
          if place?.type in ['campground', 'overnight', 'amenity'] or
              not _isEmpty place?.features
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
                  options = if trip then {qs: {tripId: trip.id}} else null
                  @router.goOverlay place.type, {slug: place.slug}, options
                Promise.resolve null
            }
          {
            $icon: new Icon()
            icon: 'star'
            text: if isSaved
              @model.l.get 'general.saved'
            else
              @model.l.get 'general.save'
            loadingText: @model.l.get 'general.saving'
            loadedText: @model.l.get 'general.saved'
            onclick: =>
              if isSaved
                Promise.resolve null
              else
                @saveCheckIn()
          }
          if place?.type is 'coordinate'
            {
              $icon: new Icon()
              icon: 'add-circle'
              text: @model.l.get 'coordinateTooltip.addPlace'
              onclick: =>
                @model.overlay.open new AddPlaceDialog {
                  @model, @router, location: place.location
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
    {place, trip, buttons, info, isEditingRoute
      isLoadingButtons, isLoadedButtons, elevation} = @state.getValue()

    isVisible ?= Boolean place

    {elevation, localMaps, attachments} = info or {}

    if not elevation? or elevation is false
      elevation = '...'

    isDisabled = not place or not (place.type in [
      'campground', 'overnight', 'amenity'
    ])

    # needs to always be an a (even for non-clickable) so vdom reuses
    z 'a.z-place-sheet', {
      className: z.classKebab {isVisible}
      href: if not isDisabled
        @router.get place?.type, {slug: place?.slug}
      onclick: (e) =>
        e?.stopPropagation()
        e?.preventDefault()
        if place?.type is 'hazard' and place?.subType is 'lowClearance'
          [lon, lat] = place.location
          @model.portal.call 'browser.openWindow', {
            url:
              "https://maps.google.com/maps?z=18&t=k&ll=#{lat},#{lon}"
          }
        else if not isDisabled
          options = if trip then {qs: {tripId: trip.id}} else null
          @router.goOverlay place.type, {slug: place.slug}, options
    },
      z '.sheet',
        if place?.hasAttachments
          z '.attachments',
            _map attachments, (attachment) =>
              src = @model.image.getSrcByPrefix attachment.prefix, {
                size: 'small'
              }

              z '.attachment',
                className: @getImageLoadHashByUrl src
                style:
                  backgroundImage: "url(#{src})"
                  width: "#{attachment.aspectRatio * 120}px"
                  height: '120px'
        z '.content',
          z '.left',
            z '.title', place?.name

            if place?.type is 'coordinate' and not isEditingRoute
              z '.elevation',
                @model.l.get 'coordinateTooltip.elevation', {replacements: {elevation}}

            if place?.type is 'hazard'
              z '.description',
                place?.description

            if info?.addStopInfo and not place?.number?
              z '.add-stop-info',
                z '.from-last-stop',
                  @model.l.get 'placeSheet.fromLastStop', {
                    replacements:
                      time: DateService.formatSeconds info.addStopInfo.fromLastStop.time, 1
                      distance: Math.round(
                        10 * info.addStopInfo.fromLastStop.distance
                      ) / 10
                  }
                if info.addStopInfo.detour?
                  z '.detour',
                    @model.l.get 'placeSheet.detour', {
                      replacements:
                        time: DateService.formatSeconds info.addStopInfo.detour.time, 1
                        distance: Math.round(
                          10 * info.addStopInfo.detour.distance
                        ) / 10
                    }

          z '.right',
            if place?.rating?
              [
                z '.rating',
                  z @$rating, {size: '18px', color: colors.$secondaryMain}
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
                  size: '24px'
                  isTouchTarget: false
                  color: colors.$bgText54
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
