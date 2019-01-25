z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Base = require '../base'
Icon = require '../icon'
FormattedText = require '../formatted_text'
ProfileDialog = require '../profile_dialog'
SearchInput = require '../search_input'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Reviews extends Base
  constructor: ({@model, @router, reviews, parent, type, Review}) ->
    @searchValue = new RxBehaviorSubject ''
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    dialogData = new RxBehaviorSubject null
    @$profileDialog = new ProfileDialog {
      @model, @router, selectedProfileDialogUser: dialogData
    }
    @$spinner = new Spinner()

    @state = z.state {
      parent: parent
      dialogData: dialogData
      reviews: reviews.map (reviews) =>
        _map reviews, (review) =>
          bodyCacheKey = "#{review.id}:text"
          reviewCacheKey = "#{review.id}:#{review.lastUpdateTime}:message"

          $body = @getCached$ bodyCacheKey, FormattedText, {
            @model, @router, text: review.body, dialogData
          }
          $el = @getCached$ reviewCacheKey, Review, {
            review, parent, @model, @router,
            dialogData, $body
          }
          # update cached version
          $el.setReview review
          $el
    }

  render: ({$emptyState} = {}) =>
    {reviews, dialogData} = @state.getValue()

    z '.z-reviews',
      z '.g-grid',
        # z '.search',
        #   z @$searchInput, {
        #     isSearchOnSubmit: true
        #     placeholder: @model.l.get 'reviews.searchPlaceholder'
        #     onsubmit: =>
        #       @router.go 'itemsBySearch', {query: @searchValue.getValue()}
        #   }
        z '.reviews',
          if not reviews?
            z @$spinner
          else if _isEmpty reviews
            z '.empty', $emptyState
          else
            _map reviews, ($review) ->
              z '.review',
                z $review

      if dialogData
        z @$profileDialog
