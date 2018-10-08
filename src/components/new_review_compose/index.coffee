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
UploadOverlay = require '../upload_overlay'
UploadImagesPreview = require '../upload_images_preview'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NewReviewCompose
  constructor: (options) ->
    {@model, @router, @overlay$, fields, uploadFn} = options
    me = @model.user.getMe()

    {@titleValueStreams, @bodyValueStreams, @attachmentsValueStreams,
      @ratingValueStreams} = fields

    @$rating = new Rating {
      valueStreams: @ratingValueStreams, isInteractive: true
    }
    @$addImageIcon = new Icon()

    @attachmentsValueStreams ?= new RxReplaySubject 1
    @$textarea = new Textarea {valueStreams: @bodyValueStreams, @error}

    @multiImageData = new RxBehaviorSubject null
    @$uploadOverlay = new UploadOverlay {@model}
    @$uploadImagesPreview = new UploadImagesPreview {
      @multiImageData
      @model
      @overlay$
      uploadFn
      # TODO: there's probably a much cleaner way to do this and onProgress....
      onUploading: (dataUrl, {clientId}) =>
        {attachments} = @state.getValue()

        attachments or= []
        @attachmentsValueStreams.next RxObservable.of(attachments.concat [
          {
            type: 'image', isUploading: true, dataUrl, clientId
          }
        ])
      onProgress: (response, {clientId}) =>
        {attachments} = @state.getValue()

        attachmentIndex = _findIndex attachments, {clientId}
        attachments[attachmentIndex].progress = response.loaded / response.total
        @attachmentsValueStreams.next RxObservable.of attachments
      onUpload: (response, {clientId}) =>
        {caption, tags, smallUrl, largeUrl, key, location,
          width, height, aspectRatio} = response

        {attachments} = @state.getValue()

        attachmentIndex = _findIndex attachments, {clientId}
        attachments[attachmentIndex] = {
          type: 'image', aspectRatio, caption, tags, location, src: smallUrl
          smallSrc: smallUrl, largeSrc: largeUrl
        }
        @attachmentsValueStreams.next RxObservable.of attachments
    }

    @state = z.state
      me: me
      isLoading: false
      title: @titleValueStreams.switch()
      body: @bodyValueStreams.switch()
      attachments: @attachmentsValueStreams.switch()
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
    {attachments, me, isLoading, title} = @state.getValue()

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

        z '.attachments',
          z '.add-image',
            z @$addImageIcon,
              icon: 'photo-add'
              isTouchTarget: false
              size: '32px'

            z '.upload-overlay',
              z @$uploadOverlay, {
                isMulti: true
                onSelect: ({files, dataUrls}) =>
                  Promise.all _map files, (file, i) ->
                    new Promise (resolve) ->
                      img = new Image()
                      img.src = dataUrls[i]
                      img.onload = ->
                        resolve {
                          file
                          dataUrl: dataUrls[i]
                          width: img.width
                          height: img.height
                        }
                  .then (multiImageData) =>
                    @multiImageData.next multiImageData
                    @overlay$.next @$uploadImagesPreview
              }
          _map attachments, ({dataUrl, smallSrc, isUploading, progress}) ->
            z '.attachment', {
              className: z.classKebab {isUploading}
              style:
                backgroundImage: "url(#{dataUrl or smallSrc})"
            },
              z '.progress', {
                style:
                  width: "#{100 * (progress or 0)}%"
              }
