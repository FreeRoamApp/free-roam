z = require 'zorium'
_map = require 'lodash/map'
_range = require 'lodash/range'

if window?
  require './index.styl'

module.exports = class InputRange
  constructor: ({@value, @minValue, @maxValue}) ->
    @state = z.state
      value: @value

  render: ({label} = {}) =>
    {value} = @state.getValue()

    value = parseInt(value)

    z '.z-input-range',
      z 'label.label',
        label
        z '.range-container',
          z 'input.range',
            type: 'range'
            min: "#{@minValue}"
            max: "#{@maxValue}"
            value: "#{value}"
            onchange: (e) =>
              @value.next e.currentTarget.value
        z '.numbers',
          _map _range(@minValue, @maxValue + 1), (number) =>
            z '.number', {
              onclick: =>
                @value.next number
            },
              if number in [@minValue, @maxValue / 2, @maxValue, value]
                number
