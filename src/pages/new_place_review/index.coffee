z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'

if window?
  require './index.styl'

module.exports = class NewPlaceReviewPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, parent}) ->
    parent = requests.switchMap ({route}) ->
      @placeModel.getBySlug route.params.slug
    id = requests.map ({route}) ->
      route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newReview = new @NewPlaceReview {@model, @router, id, parent}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    {windowSize, $newReview} = @state.getValue()

    z '.p-new-place-review', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'newReviewPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$newReview
