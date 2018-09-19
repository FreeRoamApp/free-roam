z = require 'zorium'
_map = require 'lodash/map'
_kebabCase = require 'lodash/kebabCase'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'


if window?
  require './index.styl'

module.exports = class Dropdown
  constructor: ({@value, @valueStreams, @error} = {}) ->
    @value ?= new RxBehaviorSubject null
    @error ?= new RxBehaviorSubject null

    @isFocused = new RxBehaviorSubject false

    @state = z.state {
      isFocused: @isFocused
      value: @valueStreams?.switch() or @value
      error: @error
    }

  render: ({isDisabled, options, isFirstOptionEmpty}) =>
    {value, error, isFocused} = @state.getValue()

    isDisabled ?= false
    if isFirstOptionEmpty
      options = [{value: '', text: ''}].concat options

    z '.z-dropdown',
      # vdom doesn't key defaultValue correctly if elements are switched
      # key: _kebabCase hintText
      className: z.classKebab {
        hasValue: value isnt ''
        isFocused
        isDisabled
        isError: error?
      }
      z 'select.select', {
        attributes:
          disabled: if isDisabled then true else undefined
        value: value
        oninput: z.ev (e, $$el) =>
          if @valueStreams
            @valueStreams.next RxObservable.of $$el.value
          else
            @value.next $$el.value
          $$el.blur()
        onfocus: z.ev (e, $$el) =>
          @isFocused.next true
        onblur: z.ev (e, $$el) =>
          @isFocused.next false
      },
        _map options, (option) ->
          z 'option.option', {
            value: option?.value
            attributes:
              if "#{option?.value}" is "#{value}"
                selected: true
          },
            option?.text
      z '.underline'
      if error?
        z '.error', error
