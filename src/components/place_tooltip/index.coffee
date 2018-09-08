z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

# directionsUrl = "https://maps.apple.com/?saddr=Current%20Location&daddr=#{place.location.lat},#{place.location.lon}"

module.exports = class PlaceTooltip
  constructor: ({@model, @router, @place, @position}) ->
    @$closeIcon = new Icon()

    @state = z.state {
      @place
      @position
      windowSize: @model.window.getSize()
    }

  afterMount: (@$$el) =>
    # update manually so we don't have to rerender
    @disposable = @position.subscribe (position) =>
      # keep at exact pixels or it'll get blurry
      transform = @getTransform position
      @$$el.style.transform = transform
      @$$el.style.webkitTransform = transform

  beforeUnmount: =>
    @disposable?.unsubscribe()

  getTransform: (position) =>
    "translate(#{Math.round(position?.x)}px, #{Math.round(position?.y)}px)"

  render: =>
    {place, windowSize} = @state.getValue()

    # TODO: check bounds with windowSize and line up tooltip on different side
    # use transform: translate(-100%, -50%), etc... like mapbox does .anchor-left, .anchor-right, ...

    transform = @getTransform place?.position

    z '.z-place-tooltip', {
      className: z.classKebab {isVisible: Boolean place}
      style:
        transform: transform
        webkitTransform: transform
    },
      z 'div', {
        onclick: =>
          @router.goOverlay 'place', {slug: place.slug}
      }, 'Overlay test'
      @model.l.get 'offlineOverlay.text'
      z '.close',
        z @$closeIcon,
          icon: 'close'
          isTouchTarget: true
          color: colors.$bgText54
          onclick: =>
            @place.next null
