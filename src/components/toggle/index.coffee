z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

if window?
  require './index.styl'

module.exports = class Toggle
  constructor: ({@isSelected, @isSelectedStreams, @model, @onToggle}) ->
    unless @isSelectedStreams
      @isSelectedStreams = new RxReplaySubject 1
      @isSelected ?= RxObservable.of ''
      @isSelectedStreams.next @isSelected

    @state = z.state
      isSelected: @isSelectedStreams.switch()

  toggle: ({onToggle} = {}) =>
    {isSelected} = @state.getValue()

    if @isSelected
      @isSelected.next not isSelected
    else
      @isSelectedStreams.next RxObservable.of not isSelected
    onToggle? not isSelected

  render: ({onToggle, withText} = {}) =>
    {isSelected} = @state.getValue()

    onToggle ?= @onToggle

    z '.z-toggle', {
      className: z.classKebab {isSelected, withText}
      onclick: => @toggle {onToggle}
    },
      z '.track',
        if withText and isSelected
          @model.l.get 'general.yes'
        else if withText
          @model.l.get 'general.no'

      z '.knob'
