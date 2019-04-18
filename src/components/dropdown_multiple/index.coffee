z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_kebabCase = require 'lodash/kebabCase'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'

Checkbox = require '../checkbox'

if window?
  require './index.styl'

module.exports = class DropdownMultiple
  constructor: ({@model, @valueStreams, @error, options} = {}) ->
    @value ?= new RxBehaviorSubject null
    @error ?= new RxBehaviorSubject null

    options = _map options, (option) ->
      if option.isCheckedStreams
        isCheckedStreams = option.isCheckedStreams
      else
        isCheckedStreams = new RxReplaySubject 1
        isCheckedStreams.next RxObservable.of false
      {
        option
        isCheckedStreams: isCheckedStreams
        $checkbox: new Checkbox {valueStreams: isCheckedStreams}
      }

    value = RxObservable.combineLatest(
        _map options, ({isCheckedStreams}) ->
          isCheckedStreams.switch()
        (vals...) -> vals
      )
    .map (values) ->
      _filter _map options, ({option}, i) ->
        if values[i]
          option
        else
          null

    @valueStreams ?= new RxReplaySubject 1
    @valueStreams.next value

    @state = z.state {
      value: @valueStreams?.switch()
      isOpen: false
      options: options
      error: @error
    }

  toggle: =>
    {isOpen} = @state.getValue()
    @state.set isOpen: not isOpen

  render: ({isDisabled, currentText}) =>
    {value, isOpen, options, error} = @state.getValue()

    isDisabled ?= false

    z '.z-dropdown-multiple', {
      # vdom doesn't key defaultValue correctly if elements are switched
      # key: _kebabCase hintText
      className: z.classKebab {
        hasValue: value isnt ''
        isDisabled
        isOpen
        isError: error?
      }
    },
      z '.wrapper', {
        onclick: =>
          @toggle()

      }
      z '.current', {
        onclick: @toggle
      },
        currentText
        z '.arrow'
      z '.options',
        _map options, ({option, $checkbox}) =>
          z 'label.option',
            z '.text',
              option?.text
            z '.checkbox',
              z $checkbox, {onChange: @toggle}
      if error?
        z '.error', error
