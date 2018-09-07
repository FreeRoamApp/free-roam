z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Map = require '../../components/map'
FilterDialog = require '../../components/filter_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
filter model

need to get stream of filters that includes filter values
need to be able to update filter by id

###

module.exports = class Places
  constructor: ({@model, @router, @overlay$}) ->
    me = @model.user.getMe()
    placeType = RxObservable.of([]) # TODO
    @filters = @getFilters(placeType).publishReplay(1).refCount()
    places = @getPlacesStream()
    @filterDialogField = new RxBehaviorSubject null

    @$map = new Map {@model, @router, places, @setFilterByField}
    @$filterDialog = new FilterDialog {
      @model, @router, @filterDialogField, @setFilterByField, @overlay$
    }

    @state = z.state
      filters: @filters
      filterDialogField: @filterDialogField

  setFilterByField: (field, value) =>
    @filters.take(1).subscribe (filters) =>
      _find(filters, {field}).valueSubject.next value

  showFilterDialog: =>
    @overlay$.next @$filterDialog

  getFilters: (placeType) =>
    placeType.switchMap (placeType) =>
      filters = []
      filters.push {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: @model.l.get 'campground.roadDifficulty'
        onclick: =>
          @filterDialogField.next 'roadDifficulty'
          @showFilterDialog()
        valueSubject: new RxBehaviorSubject null
      }
      filters.push {
        field: 'crowdLevel'
        type: 'maxInt'
        name: @model.l.get 'campground.crowds'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      filters.push {
        field: 'cellSignal.att.signal'
        type: 'maxInt'
        name: @model.l.get 'campground.cellSignal'
        onclick: =>
          # modal, set carrier, min signal, 4g or 3g
          @setFilterByField 'cellSignal.att.signal', 6
          null
        valueSubject: new RxBehaviorSubject null
      }
      filters.push {
        field: 'location'
        type: 'geo'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }

      RxObservable.combineLatest(
        _map filters, 'valueSubject'
        (vals...) -> vals
      )
      .map (values) ->
        _zipWith filters, values, (filter, value) ->
          _defaults {value}, filter

  getPlacesStream: =>
    @filters.switchMap (filters) =>
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
                  lt: filter.value
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

      @model.place.search {
        query:
          bool:
            filter: filter
      }

  render: =>
    {filters, filterDialogField} = @state.getValue()

    z '.z-places',
      z '.filters',
        _map filters, (filter) ->
          if filter.name
            z '.filter', {
              className: z.classKebab {
                hasMore: true, hasValue: filter.value?
              }
              onclick: filter.onclick
            }, filter.name

      z @$map
