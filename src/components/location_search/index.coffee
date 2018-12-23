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

module.exports = class LocationSearch
  constructor: ({@model, @router, @onclick, @persistValue}) ->
    @searchValue = new RxBehaviorSubject ''
    @transformProperty = @model.window.getTransformProperty()

    locations = @searchValue.debounceTime(SEARCH_DEBOUNCE).switchMap (query) =>
      if query
        ga? 'send', 'event', 'mapSearch', 'search', query
        @model.geocoder.autocomplete {query}
      else
        RxObservable.of []

    @isOpen = new RxBehaviorSubject false
    @$searchInput = new SearchInput {@model, @router, @searchValue, @isOpen}
    @$doneButton = new FlatButton()

    @state = z.state {
      locations
      @isOpen
    }

  # afterMount: (@$$el) =>
  #   checkIsReady = =>
  #     if @$$el and @$$el.clientWidth
  #       @boundingRect = @$$el?.getBoundingClientRect?()
  #     else
  #       setTimeout checkIsReady, 100
  #   checkIsReady()

  render: (props = {}) =>
    {showDoneIfEmpty, $afterSearch, $beforeResults, $afterResults,
      placeholder, locationsTitle, isAppBar} = props

    {locations, isOpen} = @state.getValue()

    placeholder ?= @model.l.get 'placesSearch.placeholder'
    locationsTitle ?= @model.l.get 'placesSearch.locationsTitle'
    isAppBar ?= true

    # if isOpen
    #   console.log @boundingRect
    #   translateY = -1 * (@boundingRect?.top or 0)
    # else
    #   translateY = 0

    z '.z-location-search', {
      className: z.classKebab {isOpen}
    },
      z '.input-container', {
        # style:
        #   "#{@transformProperty}": "translateY(#{translateY}px)"
      },
        z '.g-grid.input',
            z @$searchInput, {
              clearOnBack: false
              height: '48px'
              isAppBar: isAppBar
              alwaysShowBack: isOpen
              placeholder: if isOpen \
                           then @model.l.get 'placesSearch.openPlaceholder'
                           else placeholder
              onfocus: (e) =>
                ga? 'send', 'event', 'mapSearch', 'open'
                @isOpen.next true
                @$tooltip?.close() # FIXME: for places_search
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

      $afterSearch

      z '.overlay',
        z '.g-grid.overlay-inner',
          $beforeResults
          if showDoneIfEmpty and _isEmpty locations
            z '.done',
              z @$doneButton,
                text: @model.l.get 'general.done'
                onclick: =>
                  @isOpen.next false
          else
            z '.locations',
              z '.title', locationsTitle
              _map locations, (location) =>
                z '.location', {
                  onclick: =>
                    @onclick? location
                    if @persistValue
                      @searchValue.next location.text
                    else
                      @searchValue.next ''
                    @isOpen.next false
                },
                  z '.text',
                    location.text
                  z '.locality',
                    if location.locality
                      [
                        location.locality
                        if location.administrativeArea
                          ", #{location.administrativeArea}"
                      ]
                    else
                      location.administrativeArea
          $afterResults
