z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class InfoLevel
  constructor: ({@model, @router}) ->
    # @state = z.state {}

  render: ({value, min, max, minFlavorText, maxFlavorText}) =>
    # {} = @state.getValue()

    selectorOffsetLeft = Math.floor(100 * value / (max - min))
    isSelectorRight = selectorOffsetLeft > 50

    z '.z-info-level',
      z '.bar', {className: z.classKebab {isSelectorRight}},
        z '.selector',
          style:
            left: "#{selectorOffsetLeft}%"
      z '.bottom',
        z '.min',
          "#{min}"
          z '.flavor-text', minFlavorText
        z '.max',
          "#{max}"
          z '.flavor-text', maxFlavorText
