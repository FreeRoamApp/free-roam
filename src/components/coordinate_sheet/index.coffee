z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_kebabCase = require 'lodash/kebabCase'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
Toggle = require '../toggle'
CoordinateInfoDialog = require '../coordinate_info_dialog'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class CoordinateSheet
  constructor: (options) ->
    {@model, @router, @coordinate, @layersVisible,
      @addOptionalLayer, @addLayerById, @removeLayerById} = options

    @$directionsIcon = new Icon()
    @$addCampsiteIcon = new Icon()
    @$saveIcon = new Icon()
    @$infoIcon = new Icon()

    @state = z.state {
      @coordinate
      info: @coordinate.switchMap (coordinate) =>
        if coordinate?.type is 'coordinate'
          @model.geocoder.getCoordinateInfoFromLocation coordinate.location
          .map (info) =>
            _defaults {
              localMaps: _map info?.localMaps, (localMap) =>
                isSelectedStreams = new RxReplaySubject 1
                isSelectedStreams.next @layersVisible.map (layersVisible) ->
                  layersVisible.indexOf(localMap.slug) isnt -1
                {
                  localMap
                  isSelectedStreams
                  $toggle: new Toggle {
                    isSelectedStreams
                  }
                }
            }, info
        else
          RxObservable.of false

      isSaving: false
      isSaved: false
    }

  saveCoordinate: =>
    {coordinate} = @state.getValue()

    @state.set isSaving: true
    name = prompt 'Enter a name'
    @model.coordinate.upsert {
      name: name
      location: "#{coordinate.location[1]}, #{coordinate.location[0]}"
    }, {invalidateAll: false}
    .then ({id}) =>
      @model.checkIn.upsert {
        sourceType: 'coordinate'
        sourceId: id
        status: 'planned'
      }
    .then =>
      @state.set isSaving: false, isSaved: true

  render: ({isVisible} = {}) =>
    {coordinate, info, isSaving, isSaved, elevation} = @state.getValue()

    isVisible ?= Boolean coordinate

    {elevation, localMaps} = info or {}

    if not elevation? or elevation is false
      elevation = '...'

    z '.z-coordinate-sheet', {
      className: z.classKebab {isVisible}
    },
      z '.sheet',
        z '.content',
          z '.title', coordinate?.name
          z '.elevation',
            @model.l.get 'coordinateTooltip.elevation', {replacements: {elevation}}
          z '.buttons',
            z '.button', {
              onclick: =>
                MapService.getDirections {
                  location:
                    lat: coordinate.location[1]
                    lon: coordinate.location[0]
                }, {@model}
            },
              z '.icon',
                z @$directionsIcon,
                  icon: 'directions'
                  size: '18px'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text', @model.l.get 'general.directions'

            z '.button', {
              onclick: @saveCoordinate
            },
              z '.icon',
                z @$saveIcon,
                  icon: 'star'
                  size: '18px'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                if isSaving then @model.l.get 'general.saving'
                else if isSaved then @model.l.get 'general.saved'
                else @model.l.get 'general.save'

            if not _isEmpty coordinate?.features
              z '.button', {
                onclick: =>
                  @model.overlay.open new CoordinateInfoDialog {
                    @model, @router, coordinate, @addOptionalLayer
                    @addLayerById, @removeLayerById, @layersVisible
                  }
              },
                z '.icon',
                  z @$infoIcon,
                    icon: 'info'
                    size: '18px'
                    isTouchTarget: false
                    color: colors.$primary500
                z '.text', @model.l.get 'general.info'

            z '.button', {
              onclick: =>
                @router.go 'newCampground', {}, {
                  qs:
                    location: Math.round(coordinate.location[1] * 1000) / 1000 +
                              ',' +
                              Math.round(coordinate.location[0] * 1000) / 1000
                }
            },
              z '.icon',
                z @$addCampsiteIcon,
                  icon: 'add-circle'
                  size: '18px'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text', @model.l.get 'coordinateTooltip.addCampsite'

        unless _isEmpty localMaps
          z '.local-maps',
            _map localMaps, ({localMap, isSelectedStreams, $toggle}) =>
              z '.local-map',
                'MVUM: ' + localMap.name
                z '.toggle',
                  z $toggle, {
                    onToggle: (isSelected) =>
                      if isSelected
                        @addOptionalLayer {
                          isTemporary: true
                          name: localMap.name
                          defaultOpacity: 0.8
                          source:
                            type: 'raster'
                            url: "https://localmaps.freeroam.app/data/#{localMap.slug}.json"
                            tileSize: 256 # built as 512 block size, rendered as this for crisper look
                          layer:
                            id: localMap.slug
                            type: 'raster'
                            source: localMap.slug
                            paint: {}
                            metadata:
                              zIndex: 2
                        }
                        @addLayerById localMap.slug
                      else
                        @removeLayerById localMap.slug

                      # reset to main stream in case value changes elsewhere
                      isSelectedStreams.next @layersVisible.map (layersVisible) ->
                        layersVisible.indexOf(localMap.slug) isnt -1

                  }
