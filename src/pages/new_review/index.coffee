z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

NewReview = require '../../components/new_review'

if window?
  require './index.styl'

module.exports = class NewReviewPage
  hideDrawer: true

  constructor: ({@model, requests, @router, overlay$, serverData, parent}) ->
    type = requests.map ({route}) =>
      type = route.src.split('/')[1]
      if type in ['campground', 'amenity'] then type else 'campground'
    typeAndRequests = RxObservable.combineLatest(
      type, requests, (vals...) -> vals
    )
    parent = typeAndRequests.switchMap ([type, {route}]) =>
      @model[type].getBySlug route.params.slug
    id = requests.map ({route}) ->
      route.params.id

    @$newReview = new NewReview {@model, @router, overlay$, id, type, parent}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newReviewPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-new-review', {
      style:
        height: "#{windowSize.height}px"
    },
      @$newReview
