z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

FormattedText = require '../formatted_text'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemGuide
  constructor: ({@model, @router, item}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()

    @state = z.state
      item: item
      $why: new FormattedText {
        text: item.map (item) -> item?.why
      }
      $what: new FormattedText {
        text: item.map (item) -> item?.what
      }
      $decisions: item.map (item) ->
        _map item?.decisions, (decision) ->
          new FormattedText {
            # TODO
            text:
              if decision.text
                decision.text
                .replace /{home}/g, 'RV'
                .replace /{Home}/g, 'RV'
          }

  render: =>
    {item, products, $why, $what, $decisions} = @state.getValue()

    z '.z-item-guide',
      if item?.name
        z '.g-grid',
          z '.why',
            z '.title', @model.l.get 'item.why'
            $why
          if item.what
            z '.what',
              z '.title', @model.l.get 'item.what'
              $what
          z '.decisions',
            z '.title', @model.l.get 'item.decisions'
            _map item.decisions, (decision, i) ->
              z '.decision',
                z '.title', decision.title
                z '.text', $decisions[i]
      else
        z @$spinner
