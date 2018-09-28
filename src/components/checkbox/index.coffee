z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Checkbox
  constructor: ({@value, @valueStreams} = {}) ->
    @value ?= new RxBehaviorSubject null
    @error ?= new RxBehaviorSubject null

    @$icon = new Icon()

    @state = z.state {
      value: @valueStreams?.switch() or @value
    }

  afterMount: (@$$el) => null

  isChecked: =>
    @$$el.querySelector('.checkbox').checked

  render: ({isDisabled}) =>
    {value} = @state.getValue()

    z '.z-checkbox',
      z 'input.checkbox', {
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
      z '.icon',
        z @$icon,
          icon: 'check'
          isTouchTarget: false
          color: colors.$primary500Text
          size: '14px'
