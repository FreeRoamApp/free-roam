z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class InfoLevel
  constructor: ({@model, @router, key}) ->
    @state = z.state {key}

  render: ({value, min, max, isReversed}) =>
    {key} = @state.getValue()

    min ?= 1
    max ?= 5

    value = value?.value or 1

    fillWidth = Math.floor(100 * (value - 1) / (max - min))
    fillWidth = Math.max(fillWidth, 4)

    # TODO: just 1 flavor text. can either have in lang, or returned from db with embed...

    z '.z-info-level',
      z '.flavor-text', @model.l.get "levelText.#{key}#{Math.round value}"
      z '.bar',
        z ".fill.has-#{value}",
          className: z.classKebab {isReversed}
          style:
            width: "#{fillWidth}%"
      z '.bottom',
        z '.min',
          "#{min}"
        z '.max',
          "#{max}"
