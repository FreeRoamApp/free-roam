z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'

Map = require '../../components/map'
PlaceTooltip = require '../../components/place_tooltip'
FilterDialog = require '../../components/filter_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesMapContainer
  constructor: (options) ->
    {@model, @router, @overlay$, @placeModel, @filters, showScale, mapBounds
      @showFilters, @addPlaces, initialZoom, isTooltipDisabled} = options

    @placeModel ?= @model.campground
    @addPlaces ?= RxObservable.of []

    @filtersStream = @getFiltersStream().publishReplay(1).refCount()
    places = RxObservable.combineLatest(
      @addPlaces, @getPlacesStream(), (vals...) -> vals
    ).map ([addPlaces, places]) ->
      if places
        addPlaces.concat places
      else
        addPlaces
    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null

    @$map = new Map {
      @model, @router, places, @setFilterByField, initialZoom, showScale
      @place, @placePosition, @mapSize, mapBounds
    }
    @$placeTooltip = new PlaceTooltip {
      @model, @router, @place, position: @placePosition, @mapSize
      isDisabled: isTooltipDisabled
    }

    @state = z.state
      filters: @filtersStream
      place: @place

  setFilterByField: (field, value) =>
    @filtersStream.take(1).subscribe (filters) =>
      _find(filters, {field}).valueSubject.next value

  showFilterDialog: (filter) =>
    @overlay$.next new FilterDialog {
      @model, @router, @overlay$, filter
    }

  getFiltersStream: =>
    RxObservable.combineLatest(
      _map @filters, 'valueSubject'
      (vals...) -> vals
    )
    .map (values) =>
      _zipWith @filters, values, (filter, value) ->
        _defaults {value}, filter

  getPlacesStream: =>
    @filtersStream.switchMap (filters) =>
      mapBounds = _find(filters, {field: 'location'})?.value
      unless mapBounds
        return RxObservable.of []

      filter = _filter _map filters, (filter) ->
        unless filter.value
          return
        switch filter.type
          when 'maxInt'
            {
              range:
                "#{filter.field}":
                  lte: filter.value
            }
          when 'minInt'
            {
              range:
                "#{filter.field}":
                  gte: filter.value
            }
          when 'maxIntSeasonal'
            {
              range:
                "#{filter.field}.#{filter.value.season}":
                  lte: filter.value.value
            }
          when 'maxIntDayNight'
            {
              range:
                "#{filter.field}.#{filter.value.dayNight}":
                  lte: filter.value.value
            }
          when 'cellSignal'
            {
              range:
                "#{filter.field}.#{filter.value.carrier}.signal":
                  gte: filter.value.signal

            }
          when 'geo'
            {
              geo_bounding_box:
                "#{filter.field}":
                  top_left:
                    lat: filter.value._ne.lat
                    lon: filter.value._sw.lng
                  bottom_right:
                    lat: filter.value._sw.lat
                    lon: filter.value._ne.lng
            }

      console.log filter

      @placeModel.search {
        query:
          bool:
            filter: filter
      }

  render: =>
    {filters, place} = @state.getValue()

    z '.z-places-map-container',
      if @showFilters
        z '.filters',
          _map filters, (filter) =>
            if filter.name
              z '.filter', {
                className: z.classKebab {
                  hasMore: true, hasValue: filter.value?
                }
                onclick: =>
                  @showFilterDialog filter
              }, filter.name

      z @$map

      if place
        z @$placeTooltip
