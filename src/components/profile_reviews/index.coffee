z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_startCase = require 'lodash/startCase'

Reviews = require '../reviews'
PrimaryButton = require '../primary_button'
ProfileReview = require '../profile_review'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProfileReviews
  constructor: ({@model, @router, user}) ->
    reviews = user.switchMap (user) =>
      unless user
        return RxObservable.of null
      @model.placeReview.getAllByUserId user.id

    @$reviews = new Reviews {
      @model, @router, reviews, Review: ProfileReview
    }
    @$addReviewButton = new PrimaryButton()

    @state = z.state {
      me: @model.user.getMe()
      user
    }

  render: =>
    {me, user} = @state.getValue()

    isMe = user and user.id is me?.id

    z '.z-profile-reviews',
      z @$reviews, {
        $emptyState:
          z '.empty',
            if isMe
              @model.l.get 'profileReviews.meEmpty'
            else
              @model.l.get 'profileReviews.empty', {
                replacements:
                  name: @model.user.getDisplayName user
              }
      }
