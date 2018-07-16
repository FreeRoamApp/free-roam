z = require 'zorium'
_defaults = require 'lodash/defaults'

colors = require '../../colors'
Ripple = require '../ripple'

if window?
  require './index.styl'

module.exports = class Button
  constructor: ->
    @$ripple = new Ripple()

    @state = z.state
      backgroundColor: null
      isHovered: false
      isActive: false

  getBackgroundColor: (colors, isRaised, isHovered, isActive, isDark) ->
    if colors.c500
      if isActive
        colors.c700
      else if isHovered
        colors.c600
      else
        colors.c500
    else
      if isActive
        if isDark
          'rgba(204, 204, 204, 0.12)'
        else
          'rgba(153, 153, 153, 0.12)'
      else if isHovered
        if isDark
          'rgba(204, 204, 204, 0.12)'
        else
          'rgba(153, 153, 153, 0.12)'
      else
        null

  render: (options) =>
    {text, isDisabled, allowDisabledClick, listeners, isRaised, isFullWidth,
      isShort, isDark, isFlat, colors, onclick, type, $content,
      heightPx} = options
    {backgroundColor, isHovered, isActive} = @state.getValue()

    $content ?= text
    heightPx ?= 36
    type ?= 'button'
    isRaised ?= false
    isFlat = not isRaised
    isDisabled ?= false
    isDark ?= false
    onclick ?= (-> null)
    colors ?= {}
    colors = _defaults colors, {
      cText: if colors.ink and not isDisabled \
                   then colors.ink
                   else null
      c200: if isDark and isFlat then colors.$grey500 \
            else colors.$grey800
      c500: null
      c600: null
      c700: null
      ink: null
    }
    backgroundColor ?= @getBackgroundColor colors, isRaised, isHovered,
                                           isActive, isDark

    z '.z-button',
      className: z.classKebab {
        isRaised
        isFlat
        isShort
        isFullWidth
        isDark
        isDisabled
        allowDisabledClick
      }
      ontouchstart: =>
        @state.set isActive: true
      ontouchend: =>
        @state.set isActive: false, isHovered: false
      onmouseover: =>
        @state.set isHovered: true
      onmouseout: =>
        @state.set isHovered: false
      onmouseup: =>
        @state.set isActive: false
      onclick: (e) =>
        @state.set isHovered: false
        onclick(e)

      z 'button.button', {
        attributes:
          disabled: if isDisabled and not allowDisabledClick \
                    then true
                    else undefined
          type: type
        onmousedown: z.ev (e, $$el) =>
          @state.set isActive: true
        style:
          backgroundColor: if isDisabled then null else backgroundColor
          color: if isDisabled then null else colors.cText
          lineHeight: "#{heightPx}px"
          minHeight: "#{heightPx}px"
      },
        $content
        unless isDisabled
          @$ripple
