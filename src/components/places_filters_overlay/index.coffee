z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/combineLatest'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_groupBy = require 'lodash/groupBy'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
_pickBy = require 'lodash/pickBy'

AppBar = require '../app_bar'
ButtonBack = require '../button_back'
FlatButton = require '../flat_button'
Icon = require '../icon'
FilterContent = require '../filter_content'
MasonryGrid = require '../masonry_grid'
TooltipPositioner = require '../tooltip_positioner'
Tabs = require '../tabs'
colors = require '../../colors'

if window?
  require './index.styl'

Icon = require '../icon'

SEARCH_DEBOUNCE = 300

module.exports = class PlacesFiltersOverlay
  constructor: (options) ->
    {@model, @router, dataTypesStream, filterTypesStream, @isVisible} = options

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$resetButton = new FlatButton()
    @$filterTabs = new Tabs {@model}

    # HACK
    @$masonryGrids = {
      campground: new MasonryGrid {@model}
      overnight: new MasonryGrid {@model}
      amenity: new MasonryGrid {@model}
      hazard: new MasonryGrid {@model}
    }

    filterTypesAndDataTypes = RxObservable.combineLatest(
      filterTypesStream.take(1), dataTypesStream, (vals...) -> vals
    )

    @state = z.state {
      isVisible: @isVisible
      # FIXME: only do this stuff after opened at least once?
      filterTypes: filterTypesAndDataTypes.map ([filterTypes, dataTypes]) =>
        _pickBy _mapValues filterTypes, (filters, filterType) =>
          if _find(dataTypes, {dataType: filterType})?.isChecked
            filterGroups = _groupBy filters, ({field, filterOverlayGroup}) ->
              filterOverlayGroup or field
            _map filterGroups, (filters, field) =>
              {
                filter: filters[0]
                filters: filters
                $el: _map filters, (filter) =>
                  new FilterContent {
                    @model, filter, isGrouped: filters.length > 1
                  }
              }
    }

  render: =>
    {isVisible, dataTypes, filterTypes} = @state.getValue()

    z '.z-places-filters-overlay', {
      # without this, when switching to this tab a dom element is recycled for
      # this and occasionally is 100% visible for a split second when it
      # should be opacity 0
      key: 'places-filters-overlay'
      className: z.classKebab {isVisible, isServerSide: not window?}
    },
      z @$appBar, {
        title: @model.l.get 'placesFiltersOverlay.title'
        isFlat: true
        $topLeftButton: z @$buttonBack, {
          onclick: =>
            @isVisible.next false
        }
        $topRightButton: z '.z-places-filters-overlay_reset-button',
          z @$resetButton, {
            text: @model.l.get 'general.reset'
            onclick: =>
              _map filterTypes, (filters) ->
                _map filters, ({filters, $el}) ->
                  _map filters, (filter, i) ->
                    filter.valueStreams.next RxObservable.of null
                    $el[i].setup()
          }
      }
      z '.g-grid',
        if isVisible
          tabs = _map filterTypes, (filters, filterType) =>
            {
              $menuText: @model.l.get "placeType.#{filterType}"
              $el: z @$masonryGrids[filterType],
                columnCounts:
                  mobile: 1
                  desktop: 2
                  tablet: 2
                $elements: _map filters, ({filters, $el}) =>
                  group = filters[0].filterOverlayGroup

                  z '.z-places-filters-overlay_filter',
                    z '.inner',
                      if group
                        z '.group-title',
                          @model.l.get "placesFiltersOverlay.filterGroups.#{group}"
                      if group is 'sliders'
                        [
                          z '.description',
                            @model.l.get "placesFiltersOverlay.filterGroups.#{group}Description"
                          z '.warning',
                            @model.l.get 'filterSheet.userInputWarning'
                        ]
                      z $el
            }

          if tabs.length is 1
            z tabs[0].$el
          else
            z @$filterTabs,
              isBarFixed: false
              tabs: tabs
