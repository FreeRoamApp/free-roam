z = require 'zorium'

icons = require './icons'
Ripple = require '../ripple'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Icon
  render: (options) =>
    {icon, size, isAlignedTop, isAlignedLeft, isAlignedRight,
              isAlignedBottom, isTouchTarget, color, onclick,
              flipX, viewBox, heightRatio, hasRipple,
              touchHeight, touchWidth} = options
    size ?= '24px'
    viewBox ?= 24
    heightRatio ?= 1
    isTouchTarget ?= true
    touchWidth ?= '48px'
    touchHeight ?= '48px'
    isClickable = Boolean onclick

    tag = if hasRipple then 'a' else 'div'

    z "#{tag}.z-icon", {
      className: z.classKebab {
        isAlignedTop, isAlignedLeft, isAlignedRight,
        isAlignedBottom, isTouchTarget, isClickable
        hasRippleWhite: hasRipple and color isnt colors.$header500Icon
        hasRippleHeader: hasRipple and color is colors.$header500Icon
      }
      attributes:
        if hasRipple then tabindex: 0 else {}
      onclick: onclick
      style:
        minWidth: if isTouchTarget then touchWidth else '100%'
        minHeight: if isTouchTarget then touchHeight else '100%'
        width: size
        height: if size?.indexOf?('%') isnt -1 \
                then "#{parseInt(size) * heightRatio}%"
                else "#{parseInt(size) * heightRatio}px"
    },
      z 'svg', {
        namespace: 'http://www.w3.org/2000/svg'
        attributes:
          'viewBox': "0 0 #{viewBox} #{viewBox * heightRatio}"
        style:
          width: size
          height: if size?.indexOf?('%') isnt -1 \
                  then "#{parseInt(size) * heightRatio}%"
                  else "#{parseInt(size) * heightRatio}px"
      },
        z 'path', {
          namespace: 'http://www.w3.org/2000/svg'
          attributes:
            d: icons[icon]
            fill: color
            'fill-rule': 'evenodd'
            transform: if flipX \
                       then 'translate(12, 12) scale(-1, 1) translate(-12, -12)'
                       else 'scale(1, 1)'
        }
