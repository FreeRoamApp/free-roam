z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
UploadOverlay = require '../upload_overlay'
UploadImagePreview = require '../upload_image_preview'
Textarea = require '../textarea'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class MarkdownEditor
  constructor: (options) ->
    {@model, @valueStreams, @attachmentsValueStreams,
      @value, @error, @uploadFn} = options
    @value ?= new RxBehaviorSubject ''
    @error ?= new RxBehaviorSubject null
    @imageData = new RxBehaviorSubject null

    @$uploadImagePreview = new UploadImagePreview {
      @imageData
      @model
      @uploadFn
      onUpload: ({prefix, aspectRatio}) =>
        {attachments} = @state.getValue()

        attachments or= []
        @attachmentsValueStreams.next RxObservable.of(attachments.concat [
          {type: 'image', prefix}
        ])

        src = @model.image.getSrcByPrefix prefix, {size: 'large'}

        @$textarea.setModifier {
          pattern: "![](<#{src} =#{aspectRatio}>)"
        }
    }

    @modifiers = [
      {
        icon: 'bold'
        $icon: new Icon()
        title: 'Bold'
        pattern: '**$0**'
      }
      {
        icon: 'italic'
        $icon: new Icon()
        title: 'Italic'
        pattern: '*$0*'
      }
      # markdown doesn't support...
      # {
      #   icon: 'underline'
      #   $icon: new Icon()
      #   title: 'Underline'
      #   pattern: '__$0__'
      # }
      {
        icon: 'bullet-list'
        $icon: new Icon()
        title: 'List'
        pattern: '- $0'
      }
      {
        icon: 'image'
        $icon: new Icon()
        title: 'Image'
        pattern: '![]($1)'
        isImage: true
        $uploadOverlay: new UploadOverlay {@model}
      }
    ]

    @$textarea = new Textarea {@valueStreams, @error}

    @state = z.state {
      attachments: @attachmentsValueStreams?.switch()
    }

  render: ({hintText, imagesAllowed} = {}) =>
    imagesAllowed ?= true

    z '.z-markdown-editor',
      z '.textarea',
        z @$textarea, {hintText, isFull: true}

      z '.panel',
        _map @modifiers, (options) =>
          {icon, $icon, title, pattern, isImage,
            onclick, $uploadOverlay} = options

          if isImage and not imagesAllowed
            return

          z '.icon', {
            title: title
          },
            z $icon, {
              icon: icon
              color: colors.$bgText
              onclick: =>
                if onclick
                  onclick()
                else
                  @$textarea.setModifier {pattern, onclick}
            }
            if $uploadOverlay
              z '.upload-overlay',
                z $uploadOverlay, {
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
                      @model.overlay.open @$uploadImagePreview
                }
