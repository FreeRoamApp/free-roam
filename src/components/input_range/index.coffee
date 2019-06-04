z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_range = require 'lodash/range'

if window?
  require './index.styl'

module.exports = class InputRange
  constructor: ({@model, @value, @valueStreams, @minValue, @maxValue}) ->
    @state = z.state
      value: @valueStreams?.switch() or @value

  setValue: (value) =>
    if @valueStreams
      @valueStreams.next RxObservable.of value
    else
      @value.next value

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
              @setValue parseInt(e.currentTarget.value)
            oninput: (e) =>
              @setValue parseInt(e.currentTarget.value)
        z '.info',
          z '.unset', @model.l.get 'inputRange.default'
          z '.numbers',
            _map _range(@minValue, @maxValue + 1), (number) =>
              z '.number', {
                onclick: =>
                  @setValue parseInt(number)
              },
                if number in [@minValue, @maxValue / 2, @maxValue, value]
                  number
