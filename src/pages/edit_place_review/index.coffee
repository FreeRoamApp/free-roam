z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'

if window?
  require './index.styl'

module.exports = class EditPlaceReviewPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, parent}) ->
    parent = requests.switchMap ({route}) =>
      @placeModel.getBySlug route.params.slug

    review = requests.switchMap ({route}) =>
      @placeReviewModel.getById route.params.reviewId

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$editReview = new @EditPlaceReview {@model, @router, review, parent}

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    z '.p-edit-place-review',
      z @$appBar, {
        title: @model.l.get 'editReviewPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$editReview
