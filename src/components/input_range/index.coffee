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

    value = if value? then parseInt(value) else null

    # FIXME: handle null starting value better (clicking on mid should set value)

    z '.z-input-range', {
      className: z.classKebab {hasValue: value?}
    },
      z 'label.label',
        label
        z '.range-container',
          z 'input.range',
            type: 'range'
            min: "#{@minValue}"
            max: "#{@maxValue}"
            value: "#{value}"
            onclick: (e) =>
              @value.next parseInt(e.currentTarget.value)
            oninput: (e) =>
              @value.next parseInt(e.currentTarget.value)
        z '.info',
          z '.unset', 'Drag to set value'
          z '.numbers',
            _map _range(@minValue, @maxValue + 1), (number) =>
              z '.number', {
                onclick: =>
                  @value.next parseInt(number)
              },
                if number in [@minValue, @maxValue / 2, @maxValue, value]
                  number
