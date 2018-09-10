z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_range = require 'lodash/range'

Dialog = require '../dialog'
InputRange = require '../input_range'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterDialog
  constructor: ({@model, @overlay$, @filterDialogField, @setFilterByField}) ->
    @$dialog = new Dialog {
      onLeave: =>
        @overlay$.next null
    }

    @rangeValue = new RxBehaviorSubject 5
    # TODO
    @$inputRange = new InputRange {
      value: @rangeValue, minValue: 0, maxValue: 10
    }

    @state = z.state
      filterDialogField: @filterDialogField

  render: =>
    {filterDialogField} = @state.getValue()

    switch filterDialogField
      when 'roadDifficulty'
        $title = @model.l.get 'roadDifficulty.title'
        $content = z @$inputRange, {
          label: @model.l.get 'roadDifficulty.label'
          minFlavorText: @model.l.get 'roadDifficulty.minFlavorText'
          maxFlavorText: @model.l.get 'roadDifficulty.maxFlavorText'
        }

    z '.z-filter-dialog',
      z @$dialog,
        isVanilla: true
        $title: $title
        $content:
          z '.z-filter-dialog_dialog',
            $content
        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @overlay$.next null
        submitButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @setFilterByField filterDialogField, @rangeValue.getValue()
            @overlay$.next null
