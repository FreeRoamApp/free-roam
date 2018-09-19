z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'


if window?
  require './index.styl'

module.exports = class Checkbox
  constructor: ({@value, @valueStreams} = {}) ->
    @value ?= new RxBehaviorSubject null
    @error ?= new RxBehaviorSubject null

    @state = z.state {
      value: @valueStreams?.switch() or @value
    }

  render: ({isDisabled}) =>
    {value} = @state.getValue()

    z 'input.z-checkbox', {
      type: 'checkbox'
      attributes:
        disabled: if isDisabled then true else undefined
      checked: if value then true else undefined
      oninput: z.ev (e, $$el) =>
        if @valueStreams
          @valueStreams.next RxObservable.of $$el.checked
        else
          @value.next $$el.checked
        $$el.blur()
    }
