z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_orderBy = require 'lodash/orderBy'

FilterSheet = require '../filter_sheet'
Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'


module.exports = class PlacesFilterBar
  constructor: (options) ->
    {@model, @isFilterTypesVisible, @currentDataType, @dataTypesStream
      @filterTypesStream, tripRoute, @isTripFilterEnabled} = options

    @$switchIcon = new Icon()

    @state = z.state {
      @isFilterTypesVisible
      tripRoute
      @isTripFilterEnabled
      dataTypes: @dataTypesStream
      filterTypes: @filterTypesStream.map (filterTypes) ->
        _mapValues filterTypes, (filters) ->
          _orderBy filters, (({value}) -> value?), 'desc'
    }

  showFilterSheet: (filter) =>
    id = Date.now()
    @model.overlay.open new FilterSheet({
      @model, @router, filter, id
    }), {id}

  render: ({currentDataType, visibleDataTypes}) =>
    {isFilterTypesVisible, tripRoute, isTripFilterEnabled
      filterTypes, dataTypes} = @state.getValue()

    z '.z-places-filter-bar', {
      className: z.classKebab {
        hasMultipleDataTypes: visibleDataTypes?.length > 1
      }
    },
      z '.bar',
        z '.show', {
          onclick: =>
            unless isFilterTypesVisible
              ga? 'send', 'event', 'map', 'showTypes'
            @isFilterTypesVisible.next not isFilterTypesVisible
        },
          z @$switchIcon,
            icon: 'swap'
            color: colors.$bgText54
            isTouchTarget: false
        z '.filters', {
          className: z.classKebab {"#{currentDataType}": true}
        },
          if tripRoute
            z '.filter', {
              className: z.classKebab {
                hasValue: isTripFilterEnabled
              }
              onclick: =>
                @isTripFilterEnabled.next not isTripFilterEnabled
            }, @model.l.get 'placesFilterBar.alongRoute'
          _map filterTypes?[currentDataType], (filter) =>
            if filter.name
              z '.filter', {
                className: z.classKebab {
                  hasMore: not filter.isBoolean
                  hasValue: filter.value?
                }
                onclick: =>
                  ga? 'send', 'event', 'map', 'filterClick', filter.field
                  if filter.isBoolean
                    filter.valueStreams.next(
                      RxObservable.of (not filter.value) or null
                    )
                  else
                    @showFilterSheet filter
              }, filter.name

      z '.filter-type-selector', {
        className: z.classKebab {isVisible: isFilterTypesVisible}
        onclick: (e) ->
          e?.stopPropagation()
      },
        z '.title', @model.l.get 'placesMapContainer.typesTitle'
        _map visibleDataTypes, (type) =>
          {dataType} = type
          z '.type', {
            className: z.classKebab {
              isSelected: currentDataType is dataType
              "#{dataType}": true
            }
            onclick: =>
              ga? 'send', 'event', 'map', 'typeClick', dataType
              @currentDataType.next RxObservable.of dataType
              @isFilterTypesVisible.next false
          },
            z '.name', @model.l.get "placeTypes.#{dataType}"
