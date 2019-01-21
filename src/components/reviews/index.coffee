z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_startCase = require 'lodash/startCase'

Base = require '../base'
Icon = require '../icon'
PrimaryButton = require '../primary_button'
FormattedText = require '../formatted_text'
ProfileDialog = require '../profile_dialog'
Review = require '../review'
SearchInput = require '../search_input'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Reviews extends Base
  constructor: (options) ->
    {@model, @router, parent} = options
    @searchValue = new RxBehaviorSubject ''
    @$searchInput = new SearchInput {@model, @router, @searchValue}

    selectedProfileDialogUser = new RxBehaviorSubject null
    @$profileDialog = new ProfileDialog {
      @model, @router, selectedProfileDialogUser
    }

    @$addReviewButton = new PrimaryButton()

    @state = z.state {
      parent: parent
      selectedProfileDialogUser: selectedProfileDialogUser
      reviews: parent.switchMap (parent) =>
        unless parent?.type and @model["#{parent.type}Review"]
          return RxObservable.of null
        @model["#{parent.type}Review"].getAllByParentId parent.id
        .map (reviews) =>
          _map reviews, (review) =>
            bodyCacheKey = "#{review.id}:text"
            reviewCacheKey = "#{review.id}:#{review.lastUpdateTime}:message"

            $body = @getCached$ bodyCacheKey, FormattedText, {
              @model, @router, text: review.body, selectedProfileDialogUser
            }
            $el = @getCached$ reviewCacheKey, Review, {
              review, parent, @model, @router,
              selectedProfileDialogUser, $body
            }
            $el
    }

  render: =>
    {reviews, parent, selectedProfileDialogUser} = @state.getValue()

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
          if _isEmpty reviews
            z '.empty',
              "We don't have any reviews for this yet. If you've been here and have a few minutes, leaving a review would be incredibly helpful to other campers!"
              z '.add-review',
                z @$addReviewButton,
                  text: @model.l.get 'placeInfo.addReview'
                  onclick: =>
                    @router.go "new#{_startCase parent.type}Review", {
                      slug: parent.slug
                    }, {ignoreHistory: true}
          else
            _map reviews, ($review) ->
              z '.review',
                z $review

      if selectedProfileDialogUser
        z @$profileDialog
