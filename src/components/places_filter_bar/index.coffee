z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

FilterDialog = require '../filter_dialog'
colors = require '../../colors'

if window?
  require './index.styl'


module.exports = class PlacesFilterBar
  constructor: (options) ->
    {@model, @isFilterTypesVisible, @currentDataType,
      tripRoute, @isTripFilterEnabled} = options

    @state = z.state {
      @isFilterTypesVisible
      tripRoute
      @isTripFilterEnabled
    }

  showFilterDialog: (filter) =>
    @model.overlay.open new FilterDialog {
      @model, @router, filter
    }

  render: ({dataTypes, currentDataType, filterTypes, visibleDataTypes}) =>
    {isFilterTypesVisible, tripRoute, isTripFilterEnabled} = @state.getValue()

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
          @model.l.get 'placesMapContainer.filters'
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
                    @showFilterDialog filter
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
          },
            z '.name', @model.l.get "placeTypes.#{dataType}"
