z = require 'zorium'
_map = require 'lodash/map'
_upperFirst = require 'lodash/upperFirst'
_camelCase = require 'lodash/camelCase'
_filter = require 'lodash/filter'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterThreadsDialog
  constructor: ({@model, @isVisible, @filter, group}) ->
    @selectedSort = new RxBehaviorSubject 'popular'
    @selectedFilter = new RxBehaviorSubject 'all'

    @$dialog = new Dialog {
      onLeave: =>
        @isVisible.next false
    }

    @state = z.state
      group: group
      selectedSort: @selectedSort
      selectedFilter: @selectedFilter

  updateFilter: =>
    {selectedSort, selectedFilter} = @state.getValue()
    @filter.next {
      sort: selectedSort
      filter: selectedFilter
    }

  render: =>
    {group, selectedSort, selectedFilter} = @state.getValue()

    sortOptions = [
      {key: 'popular'}
      {key: 'new'}
    ]

    filterOptions = _filter [
      {key: 'all'}
    ]

    z '.z-filter-threads-dialog',
      z @$dialog,
        isVanilla: true
        # $title: @model.l.get 'general.filter'
        $content:
          z '.z-filter-threads-dialog_dialog',
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

            # z '.subhead', @model.l.get 'general.filter'
            # _map filterOptions, ({key, name}) =>
            #   pascalKey = _upperFirst _camelCase key
            #   z 'label.option',
            #     z 'input.radio',
            #       type: 'radio'
            #       name: 'filter'
            #       value: key
            #       checked: selectedFilter is key
            #       onchange: =>
            #         @selectedFilter.next key
            #     z '.text',
            #       @model.l.get "filterThreadsDialog.filter#{pascalKey}"

        cancelButton:
          text: @model.l.get 'general.cancel'
          onclick: =>
            @isVisible.next false
        submitButton:
          text: @model.l.get 'general.done'
          onclick: =>
            @updateFilter()
            @isVisible.next false
