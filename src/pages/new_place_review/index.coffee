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
    parent = requests.switchMap ({route}) =>
      @placeModel.getBySlug route.params.slug
    id = requests.map ({route}) ->
      route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newReview = new @NewPlaceReview {@model, @router, id, parent}

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    {$newReview} = @state.getValue()

    z '.p-new-place-review',
      z @$appBar, {
        title: @model.l.get 'newReviewPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$newReview
