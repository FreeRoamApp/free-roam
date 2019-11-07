z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Sheet = require '../sheet'
FilterContent = require '../filter_content'
FlatButton = require '../flat_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class FilterSheet
  constructor: ({@model, @filter, id}) ->
    @$content = new FilterContent {@model, @filter}
    @$resetButton = new FlatButton()
    @$sheet = new Sheet {
      @model, id
    }

    @state = z.state {
      value: @filter.valueStreams.switch()
    }

  render: =>
    {value} = @state.getValue()

    z '.z-filter-sheet',
      z @$sheet,
        isVanilla: true
        # $title: $title
        $content:
          z '.z-filter-sheet_sheet',
            z '.reset',
              if value
                z @$resetButton,
                  text: @model.l.get 'general.reset'
                  onclick: =>
                    @filter.valueStreams.next RxObservable.of null
                    @$content.setup()
            @$content
