z = require 'zorium'
_map = require 'lodash/map'
_upperFirst = require 'lodash/upperFirst'
_camelCase = require 'lodash/camelCase'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterCommentsDialog
  constructor: ({@model, @filter}) ->
    @selectedSort = new RxBehaviorSubject 'popular'

    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    @state = z.state
      selectedSort: @selectedSort

  updateFilter: =>
    {selectedSort} = @state.getValue()
    @filter.next {
      sort: selectedSort
    }

  render: =>
    {selectedSort} = @state.getValue()

    sortOptions = [
      {key: 'popular'}
      {key: 'new'}
    ]

    filterOptions = [
      {key: 'all'}
    ]

    z '.z-filter-comments-dialog',
      z @$dialog,
        isVanilla: true
        # $title: @model.l.get 'general.filter'
        $content:
          z '.z-filter-comments-dialog_dialog',
            z '.subhead', @model.l.get 'general.sort'
            _map sortOptions, ({key}) =>
              pascalKey = _upperFirst _camelCase key
              z 'label.option',
                z 'input.radio',
                  type: 'radio'
                  name: 'sort'
                  value: key
                  checked: selectedSort is key
                  onchange: =>
                    @selectedSort.next key
                z '.text',
                  @model.l.get "filterThreadsDialog.sort#{pascalKey}"

        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @model.overlay.close()
        submitButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @updateFilter()
            @model.overlay.close()
