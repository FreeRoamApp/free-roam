z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_range = require 'lodash/range'

if window?
  require './index.styl'

module.exports = class InputRange
  constructor: (options) ->
    {@model, @value, @valueStreams, @minValue, @maxValue, @onChange} = options
    @state = z.state
      value: @valueStreams?.switch() or @value

  setValue: (value) =>
    if @valueStreams
      @valueStreams.next RxObservable.of value
    else
      @value.next value

  afterMount: =>
    if @onChange
      @disposable = (@valueStreams?.switch() or @value).subscribe @onChange

  beforeUnmount: =>
    @disposable?.unsubscribe()

  render: ({hideInfo, step} = {}) =>
    {value} = @state.getValue()

    value = if value? then parseInt(value) else null

    percent = parseInt 100 * ((if value? then value else 1) - @minValue) / (@maxValue - @minValue)

    # FIXME: handle null starting value better (clicking on mid should set value)

    z '.z-input-range', {
      className: z.classKebab {hasValue: value?}
    },
      z 'label.label',
        z '.range-container',
          z "input.range.percent-#{percent}",
            type: 'range'
            min: "#{@minValue}"
            max: "#{@maxValue}"
            step: "#{step or 1}"
            value: "#{value}"
            ontouchstart: (e) ->
              e.stopPropagation()
            onclick: (e) =>
              @setValue parseInt(e.currentTarget.value)
            oninput: (e) =>
              @setValue parseInt(e.currentTarget.value)
        unless hideInfo
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
