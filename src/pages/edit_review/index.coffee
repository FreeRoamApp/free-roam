z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
EditReview = require '../../components/new_review'

if window?
  require './index.styl'

module.exports = class EditReviewPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, parent}) ->
    type = requests.map ({route}) ->
      type = route.src.split('/')[1]
      if type in ['campground', 'amenity'] then type else 'campground'
    typeAndRequests = RxObservable.combineLatest(
      type, requests, (vals...) -> vals
    )

    parent = typeAndRequests.switchMap ([type, {route}]) =>
      @model[type].getBySlug route.params.slug

    review = typeAndRequests.switchMap ([type, {route}]) =>
      @model["#{type}Review"].getById route.params.reviewId

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$editReview = new EditReview {@model, @router, review, type, parent}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-edit-review', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'editReviewPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$editReview
