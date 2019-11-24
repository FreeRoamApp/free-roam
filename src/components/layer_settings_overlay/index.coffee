z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../app_bar'
Icon = require '../icon'
InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class LayerSettingsOverlay
  constructor: ({@model, @router, optionalLayers, @setLayerOpacityById}) ->
    @$closeIcon = new Icon {@router}
    @$appBar = new AppBar {@model}

    @optionalLayers = _map optionalLayers, (optionalLayer) =>
      layer = optionalLayer.layer or optionalLayer.layers[0]
      layerId = layer.id

      layerSettings = JSON.parse localStorage?.layerSettings or '{}'
      valueSubject = new RxBehaviorSubject Math.round(100 * (
        layerSettings[layerId]?.opacity or
        optionalLayer.defaultOpacity
      ))
      $range = new InputRange {
        @model
        # TODO. figure out way to save layer info
        # layerInfo localStorage {id: {opacity: 90}}
        value: valueSubject
        minValue: 0
        maxValue: 100
        onChange: (value) =>
          layerSettings = JSON.parse localStorage?.layerSettings or '{}'
          layerSettings[layerId] ?= {}
          opacity = value / 100
          layerSettings[layerId].opacity = opacity
          localStorage.layerSettings = JSON.stringify layerSettings
          @setLayerOpacityById layerId, opacity
      }
      {optionalLayer, valueSubject, $range}

    @state = z.state
      windowSize: @model.window.getSize()

  render: =>
    {windowSize} = @state.getValue()

    z '.z-layer-settings-overlay',
      z @$appBar, {
        title: @model.l.get 'layerSettingsOverlay.title'
        $topLeftButton: z @$closeIcon, {
          icon: 'close'
          hasRipple: true
          isAlignedLeft: true
          color: colors.$header500Icon
          onclick: =>
            @model.overlay.close()
        }
      }

      z '.content',
        z '.title', @model.l.get 'layerSettingsOverlay.layerTransparencies'
        z '.layers',
          _map @optionalLayers, ({optionalLayer, valueSubject, $range}) ->
            layer = optionalLayer.layer or optionalLayer.layers[0]
            if layer.id is 'smoke'
              return
            z '.layer',
              z '.icon',
                style:
                  backgroundImage: "url(#{optionalLayer.thumb})"
              z '.info',
                z '.name', optionalLayer.name
                z '.slider',
                  z '.range',
                    z $range, {step: 10, hideInfo: true}
                  z '.percent',
                    "#{valueSubject.getValue()}%"
