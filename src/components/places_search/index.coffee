z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/debounceTime'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

SearchInput = require '../search_input'
FlatButton = require '../flat_button'
Tooltip = require '../tooltip'
colors = require '../../colors'

if window?
  require './index.styl'

Icon = require '../icon'

SEARCH_DEBOUNCE = 300

module.exports = class PlacesSearch
  constructor: ({@model, @router, @onclick}) ->
    @searchValue = new RxBehaviorSubject ''

    locations = @searchValue.debounceTime(SEARCH_DEBOUNCE).switchMap (query) =>
      if query
        ga? 'send', 'event', 'mapSearch', 'search', query
        @model.geocoder.autocomplete {query}
      else
        RxObservable.of []

    @isOpen = new RxBehaviorSubject false
    @$searchInput = new SearchInput {@model, @router, @searchValue, @isOpen}
    @$doneButton = new FlatButton()
    @$tooltip = new Tooltip {
      @model
      key: 'placeSearch'
      anchor: 'top-left'
      offset:
        left: 48
    }

    @state = z.state {
      locations
      @isOpen
    }

  render: ({dataTypes}) =>
    {locations, isOpen} = @state.getValue()

    console.log locations

    z '.z-places-search', {
      className: z.classKebab {isOpen}
    },
      z '.input-container',
        z '.input',
          z @$searchInput, {
            clearOnBack: false
            height: '48px'
            isAppBar: true
            alwaysShowBack: isOpen
            placeholder: if isOpen \
                         then @model.l.get 'placesSearch.openPlaceholder'
                         else @model.l.get 'placesSearch.placeholder'
            onfocus: (e) =>
              ga? 'send', 'event', 'mapSearch', 'open'
              @isOpen.next true
              @$tooltip.close()
            ontouchstart: =>
              # reduce jank in map
              # (doesn't need to resize for kb when overlay is up)
              @model.window.pauseResizing()
            onblur: (e) =>
              setTimeout =>
                @model.window.resumeResizing()
              , 200 # give time for keyboard animation to finish
            onBack: (e) =>
              e?.stopPropagation()
              @isOpen.next false
          }

      # tooltip here. need easy way of adding this
      z @$tooltip, {
        $title: 'Search for campgrounds and more'
        $content: 'Tap above to find whatever you\'re looking for. Campsites, dump stations, Walmarts, you name it!'
      }

      z '.overlay',
        z '.overlay-inner',
          z '.data-types',
            z '.title', @model.l.get 'placesSearch.dataTypesTitle'

            z '.g-grid',
              z '.g-cols',
              _map dataTypes, (type) =>
                {dataType, onclick, $checkbox, isCheckedSubject, layer} = type
                z '.g-col.g-xs-6.g-md-3',
                  z 'label.type', {
                    onclick: ->
                      ga? 'send', 'event', 'mapSearch', 'dataType', dataType
                    className: z.classKebab {
                      "#{dataType}": true
                    }
                  },
                    z '.checkbox',
                      z $checkbox
                    z '.info',
                      z '.name', @model.l.get "placeTypes.#{dataType}"
                      z '.description',
                        @model.l.get "placeTypes.#{dataType}Description"

          if _isEmpty locations
            z '.done',
              z @$doneButton,
                text: @model.l.get 'general.done'
                onclick: =>
                  @isOpen.next false
          else
            z '.locations',
              z '.title', @model.l.get 'placesSearch.locationsTitle'
              _map locations, (location) =>
                z '.location', {
                  onclick: =>
                    @onclick? location
                    @searchValue.next location.text
                    @isOpen.next false
                },
                  z '.text',
                    # geocoded locations are 'text', campgrounds are 'name'
                    location.text or location.name
                  z '.locality',
                    if location.locality
                      [
                        location.locality
                        if location.administrativeArea
                          ", #{location.administrativeArea}"
                      ]
                    else
                      location.administrativeArea
