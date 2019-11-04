z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/debounceTime'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

AppBar = require '../app_bar'
Icon = require '../icon'
SearchInput = require '../search_input'
FlatButton = require '../flat_button'
TooltipPositioner = require '../tooltip_positioner'
colors = require '../../colors'

if window?
  require './index.styl'

Icon = require '../icon'

SEARCH_DEBOUNCE = 300

module.exports = class PlacesFiltersOverlay
  constructor: (options) ->
    {@model, @router, dataTypesStream} = options

    @$appBar = new AppBar {@model}

    @state = z.state {
      dataTypes: dataTypesStream
    }

  render: =>
    {dataTypes} = @state.getValue()

    z '.z-places-filters-overlay', {
      # without this, when switching to this tab a dom element is recycled for
      # this and occasionally is 100% visible for a split second when it
      # should be opacity 0
      key: 'places-filters-overlay'
    },
      z @$appBar, {
        title: @model.l.get 'placesFiltersOverlay.title'
        $topLeftButton: z @$buttonBack, {
          color: colors.$primaryMainText
        }
      }
      if dataTypes
        z '.data-types',
          z '.title', @model.l.get 'placesSearch.dataTypesTitle'

          z '.g-grid',
            z '.g-cols',
            _map dataTypes, (type) =>
              {dataType, onclick, $checkbox, layer} = type
              z '.g-col.g-xs-12.g-md-3',
                z 'label.type', {
                  onclick: ->
                    ga? 'send', 'event', 'mapSearch', 'dataType', dataType
                  className: z.classKebab {
                    "#{dataType}": true
                  }
                },
                  z '.info',
                    z '.name', @model.l.get "placeTypes.#{dataType}"
                    z '.description',
                      @model.l.get "placeTypes.#{dataType}Description"
                  z '.checkbox', z $checkbox
