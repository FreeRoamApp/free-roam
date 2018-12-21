z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_findIndex = require 'lodash/findIndex'

Icon = require '../icon'
Rating = require '../rating'
Textarea = require '../textarea'
UploadImagesList = require '../upload_images_list'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NewReviewCompose
  constructor: (options) ->
    {@model, @router, fields, uploadFn} = options
    me = @model.user.getMe()

    {@titleValueStreams, @bodyValueStreams, @attachmentsValueStreams,
      @ratingValueStreams} = fields

    @$rating = new Rating {
      valueStreams: @ratingValueStreams, isInteractive: true
    }

    @attachmentsValueStreams ?= new RxReplaySubject 1
    @$textarea = new Textarea {valueStreams: @bodyValueStreams, @error}
    @$uploadImagesList = new UploadImagesList {
      @model, @router, @attachmentsValueStreams, uploadFn
    }

    @state = z.state
      me: me
      isLoading: false
      title: @titleValueStreams.switch()
      body: @bodyValueStreams.switch()
      rating: @ratingValueStreams.switch()

  isCompleted: =>
    {title, body, rating, me} = @state.getValue()
    me?.username is 'austin' or (title and body and rating)

  getTitle: =>
    @model.l.get 'newReviewPage.title'

  setTitle: (e) =>
    @titleValueStreams.next RxObservable.of e.target.value

  setBody: (e) =>
    @bodyValueStreams.next RxObservable.of e.target.value

  render: ({onDone}) =>
    {me, isLoading, title} = @state.getValue()

    z '.z-new-review-compose',
      z '.g-grid',
        z '.rating',
          z @$rating, {size: '40px'}
        z 'input.title',
          type: 'text'
          onkeyup: @setTitle
          onchange: @setTitle
          # bug where cursor goes to end w/ just value
          defaultValue: title or ''
          placeholder: @model.l.get 'compose.titleHintText'

        z '.divider'

        z '.textarea',
          z @$textarea, {
            hintText: @model.l.get 'composeReview.bodyHintText'
            isFull: true
          }

        z '.divider'

        z @$uploadImagesList
