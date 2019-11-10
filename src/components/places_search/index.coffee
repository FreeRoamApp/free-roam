z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/debounceTime'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
DataTypesSheet = require '../data_types_sheet'
SearchInput = require '../search_input'
FlatButton = require '../flat_button'
TooltipPositioner = require '../tooltip_positioner'
colors = require '../../colors'

if window?
  require './index.styl'

Icon = require '../icon'

SEARCH_DEBOUNCE = 300

module.exports = class PlacesSearch
  constructor: (options) ->
    {@model, @router, @onclick, searchQuery, @persistValue, @dataTypesStream
      @filterTypesStream, @hasDirectPlaceLinks, @isAppBar} = options

    @searchValueStreams = new RxReplaySubject 1
    @searchValueStreams.next searchQuery or (new RxBehaviorSubject '')

    locations = @searchValueStreams.switch()
    .debounceTime(SEARCH_DEBOUNCE).switchMap (query) =>
      if query
        ga? 'send', 'event', 'mapSearch', 'search', query
        @model.geocoder.autocomplete {query}
      else
        RxObservable.of []
    .map (locations) ->
      _map locations, (location) ->
        $visitIcon = if location.type is 'campground' then new Icon() else null
        {
          location
          $icon: new Icon()
          $visitIcon
        }

    @isOpen = new RxBehaviorSubject false
    @$searchInput = new SearchInput {
      @model, @router, @searchValueStreams, onFocus: => @isOpen.next true
    }
    @$eyeIcon = new Icon()
    @$doneButton = new FlatButton()
    @$searchTooltip = new TooltipPositioner {
      @model
      key: 'placeSearch'
      anchor: 'top-left'
      offset:
        left: 48
    }
    @$typesTooltip = new TooltipPositioner {
      @model
      key: 'mapTypes'
      offset:
        left: 58
    }

    @state = z.state {
      locations
      @isOpen
    }

  render: (props = {}) =>
    {locations, isOpen} = @state.getValue()

    {placeholder, locationsTitle} = props

    placeholder ?= @model.l.get 'placesSearch.placeholder'
    locationsTitle ?= @model.l.get 'placesSearch.locationsTitle'

    z '.z-places-search', {
      className: z.classKebab {isOpen, isServerSide: not window?}
    },
      z '.input-container',
        z '.input',
          z @$searchInput, {
            clearOnBack: false
            height: '48px'
            isAppBar: @isAppBar
            alwaysShowBack: isOpen
            $topRightButton:
              z '.z-places-search_search-top-right',
                z @$eyeIcon,
                  icon: 'eye'
                  color: colors.$bgText54
                  onclick: (e) =>
                    @model.overlay.open new DataTypesSheet({
                      @model, @dataTypesStream, id: 'dataTypes'
                    }), {id: 'dataTypes'}
                    @$typesTooltip.close()
                z @$typesTooltip
            placeholder: if isOpen \
                         then @model.l.get 'placesSearch.openPlaceholder'
                         else @model.l.get 'placesSearch.placeholder'
            onfocus: (e) =>
              ga? 'send', 'event', 'mapSearch', 'open'
              @isOpen.next true
              @$searchTooltip.close()
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

      z @$searchTooltip

      z '.overlay', {
        # without this, when switching to this tab a dom element is recycled for
        # this and occasionally is 100% visible for a split second when it
        # should be opacity 0
        key: 'places-search-overlay'
      },
        z '.overlay-inner',
          if not _isEmpty locations
            z '.locations',
              # z '.title', @model.l.get 'placesSearch.locationsTitle'
              _map locations, ({location, $icon, $visitIcon}) =>
                z '.location', {
                  onclick: =>
                    @model.geocoder.getBoundingFromLocation location.location
                    .then (bboxWithPlaces) =>
                      # combine, since bboxWithPlaces is too small for states
                      if location.bbox
                        bboxWithPlaces = {
                          x1: Math.min location.bbox[0], bboxWithPlaces.x1
                          y1: Math.min location.bbox[1], bboxWithPlaces.y1
                          x2: Math.max location.bbox[2], bboxWithPlaces.x2
                          y2: Math.max location.bbox[3], bboxWithPlaces.y2
                        }
                      @onclick {
                        bbox: bboxWithPlaces, location: location.location
                        text: location.name or location.text
                        sourceType: location.type or 'coordinate'
                        sourceId: location.id
                        slug: location.slug
                      }
                    @searchValueStreams.next RxObservable.of location.text
                    @isOpen.next false
                },
                  z '.icon',
                    z $icon,
                      icon: 'location'
                      color: colors.$bgText54
                      isTouchTarget: false
                  z '.content',
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
                    if location.type and @hasDirectPlaceLinks
                      z '.open',
                        z $visitIcon,
                          icon: 'open'
                          color: colors.$bgText54
                          isTouchTarget: false
                          size: '20px'
                          onclick: =>
                            @router.go 'campground', {
                              slug: location.slug
                            }
