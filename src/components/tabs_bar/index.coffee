z = require 'zorium'
_map = require 'lodash/map'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TabsBar
  type: 'Widget'

  constructor: ({@selectedIndex}) ->
    @state = z.state
      selectedIndex: @selectedIndex

  # update: ($$prev, $$el) ->
  #   prevLeft = $$prev.style.left
  #   $$prev.style.left = 'auto'
  #   $$el = prevLeft

  onTouchMove: (e) ->
    e.preventDefault()

  afterMount: (@$$el) =>
    @$$el.addEventListener 'touchmove', @onTouchMove

  beforeUnmount: =>
    @$$el?.removeEventListener 'touchmove', @onTouchMove

  render: (props) =>
    {items, bgColor, color, style, inactiveColor, underlineColor, isFixed,
      isFlat, tabWidth} = props
    {selectedIndex} = @state.getValue()

    bgColor ?= colors.$tertiary0
    inactiveColor ?= colors.$bgText54
    color ?= colors.$bgText
    underlineColor ?= colors.$primary500

    isFullWidth = not tabWidth

    z '.z-tabs-bar', {
      className: z.classKebab {isFixed, isFlat, isFullWidth}
      style:
        background: bgColor
    },
      z '.g-grid',
        z '.bar', {
          style:
            background: bgColor
            width: if isFullWidth \
                   then '100%'
                   else "#{tabWidth * items.length}px"
        },
            z '.selector',
              key: 'selector'
              style:
                background: underlineColor
                width: "#{100 / items.length}%"
            _map items, (item, i) =>
              hasIcon = Boolean item.$menuIcon
              hasText = Boolean item.$menuText
              hasNotification = item.hasNotification
              isSelected = i is selectedIndex

              z '.tab',
                key: i
                slug: item.slug
                className: z.classKebab {hasIcon, hasText, isSelected}
                style: if tabWidth then {width: "#{tabWidth}px"} else null

                onclick: (e) =>
                  e.preventDefault()
                  e.stopPropagation()
                  @selectedIndex.next(i)
                if hasIcon
                  z '.icon',
                    z item.$menuIcon,
                      isTouchTarget: false
                      color: if isSelected then color else inactiveColor
                      icon: item.menuIconName
                item.$after
                if hasText
                  z '.text', {
                    style:
                      color: if isSelected then color else inactiveColor
                  },
                   item.$menuText

                 z '.notification', {
                   className: z.classKebab {
                     isVisible: hasNotification
                   }
                 }
