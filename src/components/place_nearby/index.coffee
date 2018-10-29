z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_reduce = require 'lodash/reduce'

Fab = require '../fab'
Icon = require '../icon'
PlacesMapContainer = require '../places_map_container'
PlacesList = require '../places_list'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceNearby
  constructor: ({@model, @router, @place}) ->

    addPlaces = @place.map (place) ->
      unless place
        return []
      [{
        name: place.name
        slug: place.slug
        type: place.type
        location: place.location
      }]

    mapBounds = @place.switchMap (place) =>
      unless place
        return RxObservable.of {}
      @model[place.type].getAmenityBoundsById place.id

    @isCellTowersChecked = new RxBehaviorSubject false

    @$fab = new Fab()
    @$addIcon = new Icon()
    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, initialZoom: 9
      showScale: true, addPlaces, mapBounds, isFilterBarHidden: true
      dataTypes: [
        {
          dataType: 'amenity'
          filters: @getAmenityFilters()
          defaultValue: true
        }
        {
          dataType: 'cellTower'
          filters: @getCellTowerFilters()
          isCheckedSubject: @isCellTowersChecked
        }
      ]
      optionalLayers: MapService.getOptionalLayers {@model}
    }
    # TODO: better solution than @$placesMapContainer.getPlacesStream()?
    placesStream = @$placesMapContainer.getPlacesStream()
    placeAndPlacesStream = RxObservable.combineLatest(
      @place, placesStream, (vals...) -> vals
    )
    @$placesList = new PlacesList {
      @model, @router
      places: placeAndPlacesStream.map ([place, places]) ->
        knownTimes = _reduce place?.distanceTo, (obj, {id, time}) ->
          obj[id] = time
          obj
        , {}
        _map places, (nearbyPlace) ->
          if knownTime = knownTimes[nearbyPlace.id]
            _defaults {
              name: "#{nearbyPlace.name} (#{knownTime} min away)"
            }, nearbyPlace
          else
            nearbyPlace

    }

    @state = z.state {
      @isCellTowersChecked
      @place
    }

  getAmenityFilters: =>
    []

  getCellTowerFilters: =>
    []

  render: =>
    {isCellTowersChecked, place} = @state.getValue()

    z '.z-place-nearby',
      z '.map', {
        ontouchstart: (e) -> e.stopPropagation()
        onmousedown: (e) -> e.stopPropagation()
      },
        z @$placesMapContainer
        z '.toggle-cell-towers', {
          onclick: =>
            @isCellTowersChecked.next not isCellTowersChecked
        },
          if isCellTowersChecked
            @model.l.get 'campgroundNearby.hideCellTowers'
          else
            @model.l.get 'campgroundNearby.showCellTowers'
      z '.places-list',
        z @$placesList

      z '.fab',
        z @$fab,
          colors:
            c500: colors.$primary500
          $icon: z @$addIcon, {
            icon: 'add'
            isTouchTarget: false
            color: colors.$primary500Text
          }
          onclick: =>
            @router.go 'newAmenity', {}, {
              qs: {center: "#{place.location.lat},#{place.location.lon}"}
            }
