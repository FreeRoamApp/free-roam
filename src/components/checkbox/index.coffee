z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
allColors = require '../../colors'

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

  render: ({isDisabled, colors, onChange}) =>
    {value} = @state.getValue()

    colors = _defaults colors or {}, {
      checked: allColors.$primary500
      checkedBorder: allColors.$primary900
      border: allColors.$bgText26
      background: allColors.$tertiary100
    }

    z '.z-checkbox',
      z 'input.checkbox', {
        type: 'checkbox'
        style:
          background: if value then colors.checked else colors.background
          border: if value \
                  then "1px solid #{colors.checkedBorder}"
                  else "1px solid #{colors.border}"
        attributes:
          disabled: if isDisabled then true else undefined
        checked: if value then true else undefined
        onchange: z.ev (e, $$el) =>
          if @valueStreams
            @valueStreams.next RxObservable.of $$el.checked
          else
            @value.next $$el.checked
          onChange?()
          $$el.blur()
      }
      z '.icon',
        z @$icon,
          icon: 'check'
          isTouchTarget: false
          color: allColors.$primary500Text
          size: '16px'
