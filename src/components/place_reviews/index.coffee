z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_startCase = require 'lodash/startCase'

Reviews = require '../reviews'
PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceReviews
  constructor: ({@model, @router, place}) ->
    reviews = place.switchMap (place) =>
      unless place?.type and @model["#{place.type}Review"]
        return RxObservable.of null
      @model["#{place.type}Review"].getAllByParentId place.id

    @$reviews = new Reviews {
      @model, @router, reviews: reviews
    }
    @$addReviewButton = new PrimaryButton()


    @state = z.state {place}

  render: =>
    {place} = @state.getValue()

    z '.z-place-reviews',
      z @$reviews, {
        $emptyState:
          z '.empty',
            "We don't have any reviews for this yet. If you've been here and have a few minutes, leaving a review would be incredibly helpful to other campers!"
            z '.add-review',
              z @$addReviewButton,
                text: @model.l.get 'placeInfo.addReview'
                onclick: =>
                  @router.go "new#{_startCase place.type}Review", {
                    slug: place.slug
                  }, {ignoreHistory: true}
      }
