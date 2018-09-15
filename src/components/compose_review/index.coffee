z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Icon = require '../icon'
ActionBar = require '../action_bar'
Rating = require '../rating'
Textarea = require '../textarea'
UploadOverlay = require '../upload_overlay'
UploadImagePreview = require '../upload_image_preview'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ComposeReview
  constructor: (options) ->
    {@model, @router, @titleValueStreams, @overlay$, @ratingValueStreams
      @bodyValueStreams, @attachmentsValueStreams, uploadFn} = options
    me = @model.user.getMe()

    @$actionBar = new ActionBar {@model}
    @$rating = new Rating {
      valueStreams: @ratingValueStreams, isInteractive: true
    }
    @$addImageIcon = new Icon()

    @attachmentsValueStreams ?= new RxReplaySubject 1
    @$textarea = new Textarea {valueStreams: @bodyValueStreams, @error}

    @imageData = new RxBehaviorSubject null
    @$uploadOverlay = new UploadOverlay {@model}
    @$uploadImagePreview = new UploadImagePreview {
      @imageData
      @model
      @overlay$
      uploadFn
      onUpload: ({smallUrl, largeUrl, key, width, height}) =>
        {attachments} = @state.getValue()

        attachments or= []
        @attachmentsValueStreams.next RxObservable.of(attachments.concat [
          {type: 'image', src: smallUrl, smallSrc: smallUrl, largeSrc: largeUrl}
        ])
    }

    @state = z.state
      me: me
      isLoading: false
      titleValue: @titleValueStreams?.switch()
      attachments: @attachmentsValueStreams.switch()

  setTitle: (e) =>
    @titleValueStreams.next RxObservable.of e.target.value

  setBody: (e) =>
    @bodyValueStreams.next RxObservable.of e.target.value

  beforeUnmount: =>
    @attachmentsValueStreams.next new RxBehaviorSubject []

  render: ({onDone}) =>
    {attachments, me, isLoading, titleValue} = @state.getValue()

    z '.z-compose-review',
      z @$actionBar, {
        isSaving: isLoading
        cancel:
          text: 'Discard'
          onclick: =>
            @router.back()
        save:
          text: 'Done'
          onclick: (e) =>
            unless isLoading
              @state.set isLoading: true
              onDone e
              .catch -> null
              .then =>
                @state.set isLoading: false
      }
      z '.g-grid',
        z '.rating',
          z @$rating, {size: '40px'}
        z 'input.title',
          type: 'text'
          onkeyup: @setTitle
          onchange: @setTitle
          # bug where cursor goes to end w/ just value
          defaultValue: titleValue or ''
          placeholder: @model.l.get 'compose.titleHintText'

        z '.divider'

        z '.textarea',
          z @$textarea, {
            hintText: @model.l.get 'composeReview.bodyHintText'
            isFull: true
          }

        z '.divider'

        z '.attachments',
          z '.add-image', {
            onclick: =>
              null
          },
            z @$addImageIcon,
              icon: 'photo-add'
              isTouchTarget: false
              size: '32px'

            z '.upload-overlay',
              z @$uploadOverlay, {
                onSelect: ({file, dataUrl}) =>
                  img = new Image()
                  img.src = dataUrl
                  img.onload = =>
                    @imageData.next {
                      file
                      dataUrl
                      width: img.width
                      height: img.height
                    }
                    @overlay$.next @$uploadImagePreview
              }
          _map attachments, (attachment) ->
            z '.attachment',
              style:
                backgroundImage: "url(#{attachment.smallSrc})"
