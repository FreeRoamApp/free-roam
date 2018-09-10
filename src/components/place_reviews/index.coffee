z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
SearchInput = require '../search_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceReviews
  constructor: ({@model, @router}) ->
    @searchValue = new RxBehaviorSubject ''
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-place-reviews',
      z '.g-grid',
        z '.search',
          z @$searchInput, {
            isSearchIconRight: true
            placeholder: @model.l.get 'reviews.searchPlaceholder'
            onsubmit: =>
              @router.go 'itemsBySearch', {query: @searchValue.getValue()}
          }
