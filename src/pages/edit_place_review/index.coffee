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

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    {windowSize, $editReview} = @state.getValue()

    z '.p-edit-place-review', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'editReviewPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$editReview
