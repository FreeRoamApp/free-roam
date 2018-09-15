z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Base = require '../base'
Icon = require '../icon'
FormattedText = require '../formatted_text'
Review = require '../review'
SearchInput = require '../search_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Reviews extends Base
  constructor: ({@model, @router, parent, selectedProfileDialogUser}) ->
    @searchValue = new RxBehaviorSubject ''
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    @state = z.state {
      parent: parent
      reviews: parent.switchMap (parent) =>
        unless parent.type
          return RxObservable.of null
        @model["#{parent.type}Review"].getAllByParentId parent.id
        .map (reviews) =>
          _map reviews, (review) =>
            bodyCacheKey = "#{review.id}:text"
            reviewCacheKey = "#{review.id}:#{review.lastUpdateTime}:message"

            $body = @getCached$ bodyCacheKey, FormattedText, {
              @model, @router, text: review.body, selectedProfileDialogUser
              @overlay$
            }
            $el = @getCached$ reviewCacheKey, Review, {
              review, @model, @router, @overlay$,
              selectedProfileDialogUser, $body
            }
            $el
    }

  render: =>
    {reviews, parent} = @state.getValue()

    z '.z-reviews',
      z '.g-grid',
        z '.search',
          z @$searchInput, {
            isSearchIconRight: true
            placeholder: @model.l.get 'reviews.searchPlaceholder'
            onsubmit: =>
              @router.go 'itemsBySearch', {query: @searchValue.getValue()}
          }
        z '.reviews',
          if _isEmpty reviews
            z '.empty', @model.l.get 'reviews.empty'
          else
            _map reviews, ($review) ->
              z $review
