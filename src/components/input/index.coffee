z = require 'zorium'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/switch'

allColors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Input
  constructor: ({@value, @valueStreams, @error, @isFocused} = {}) ->
    @value ?= new RxBehaviorSubject ''
    @error ?= new RxBehaviorSubject null

    @isFocused ?= new RxBehaviorSubject false

    @state = z.state {
      isFocused: @isFocused
      value: @valueStreams?.switch() or @value
      error: @error
    }

  render: (props) =>
    {colors, hintText, type, isFloating, isDisabled, isFullWidth, autoCapitalize
      isDark, isCentered, disableAutoComplete} = props

    {value, error, isFocused} = @state.getValue()

    colors = _defaults colors, {
      c500: allColors.$tertiary900
      background: allColors.$bgText12
      underline: allColors.$primary500
    }
    hintText ?= ''
    type ?= 'text'
    isFloating ?= false
    isDisabled ?= false
    autoCapitalize ?= true

    z '.z-input',
      className: z.classKebab {
        isDark
        isFloating
        hasValue: value isnt ''
        isFocused
        isDisabled
        isCentered
        isError: error?
      }
      style:
        backgroundColor: colors.background
      z '.hint', {
        # style:
        #   color: if isFocused and not error? \
        #          then colors.c500 else null
      },
        hintText
      z 'input.input',
        attributes:
          disabled: if isDisabled then true else undefined
          autocomplete: if disableAutoComplete then 'off' else undefined
          # hack to get chrome to not autofill
          readonly: if disableAutoComplete then true else undefined
          autocapitalize: if not autoCapitalize then 'off' else undefined
          type: type
        value: value or ''
        oninput: z.ev (e, $$el) =>
          if @valueStreams
            @valueStreams.next RxObservable.of $$el.value
          else
            @value.next $$el.value
        onfocus: z.ev (e, $$el) =>
          if disableAutoComplete
            $$el.removeAttribute 'readonly' # hack to get chrome to not autofill
          @isFocused.next true
        onblur: z.ev (e, $$el) =>
          @isFocused.next false
      z '.underline-wrapper',
        z '.underline',
          style:
            backgroundColor: if isFocused and not error? \
                             then colors.underline or colors.c500 else null
      if error?
        z '.error', error
