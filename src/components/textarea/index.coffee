z = require 'zorium'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

allColors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Textarea
  constructor: ({@value, @valueStreams, @error, @isFocused} = {}) ->
    @value ?= new RxBehaviorSubject ''
    @error ?= new RxBehaviorSubject null

    @isFocused ?= new RxBehaviorSubject false

    @state = z.state {
      isFocused: @isFocused
      value: @valueStreams?.switch() or @value
      error: @error
    }

  afterMount: ($$el) =>
    @$$textarea = $$el.querySelector('.textarea')

  setValueFromEvent: (e) =>
    e?.preventDefault()

    @setValue e.target.value

  setValue: (value, {updateDom} = {}) =>
    if @valueStreams
      @valueStreams.next RxObservable.of value
    else
      @value.next value

    if updateDom
      @$$textarea.value = value

  setModifier: ({pattern}) =>
    # TODO: figure out a way to have this not be in state (bunch of re-renders)
    # problem is the valueStreams / switch
    {value} = @state.getValue()

    startPos = @$$textarea.selectionStart
    endPos = @$$textarea.selectionEnd
    selectedText = value.substring startPos, endPos
    newSelectedText = pattern.replace '$0', selectedText
    newOffset = pattern.indexOf '$0'
    if newOffset is -1
      newOffset = pattern.length
    newValue = value.substring(0, startPos) + newSelectedText +
               value.substring(endPos, value.length)
    @setValue newValue, {updateDom: true}
    @$$textarea.focus()
    @$$textarea.setSelectionRange startPos + newOffset, endPos + newOffset

  render: (props) =>
    {colors, hintText, type, isFloating, isDisabled, isFull,
      isDark, isCentered} = props

    {value, error, isFocused} = @state.getValue()

    colors = _defaults colors, {
      c500: allColors.$tertiary900Text54
      background: allColors.$tertiary900Text12
      underline: allColors.$primary500
    }
    hintText ?= ''
    type ?= 'text'
    isFloating ?= false
    isDisabled ?= false

    z '.z-textarea',
      className: z.classKebab {
        isDark
        isFloating
        hasValue: value isnt ''
        isFocused
        isDisabled
        isCentered
        isFull
        isError: error?
      }
      style:
        backgroundColor: colors.background
      z '.hint', {
        style:
          color: if isFocused and not error? \
                 then colors.c500 else null
      },
        hintText
      z 'textarea.textarea',
        attributes:
          disabled: if isDisabled then true else undefined
          type: type
        value: value
        oninput: z.ev (e, $$el) =>
          if @valueStreams
            @valueStreams.next RxObservable.of $$el.value
          else
            @value.next $$el.value
        onfocus: z.ev (e, $$el) =>
          @isFocused.next true
        onblur: z.ev (e, $$el) =>
          @isFocused.next false

        # onkeyup: @setValueFromEvent
        # bug where cursor goes to end w/ just value
        defaultValue: value or ''
      z '.underline-wrapper',
        z '.underline',
          style:
            backgroundColor: if isFocused and not error? \
                             then colors.underline or colors.c500 else null
      if error?
        z '.error', error
