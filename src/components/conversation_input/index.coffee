z = require 'zorium'
_map = require 'lodash/map'
_pick = require 'lodash/pick'
_maxBy = require 'lodash/maxBy'
_upperFirst = require 'lodash/upperFirst'
supportsWebP = window? and require 'supports-webp'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/switchMap'
require 'rxjs/add/observable/of'

Icon = require '../icon'
UploadOverlay = require '../upload_overlay'
UploadImagePreview = require '../upload_image_preview'
ConversationInputTextarea = require '../conversation_input_textarea'
ConversationInputGifs = require '../conversation_input_gifs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ConversationInput
  constructor: (options) ->
    {@model, @router, @message, @onPost, @onResize, meGroupUser,
      @inputTranslateY, allowedPanels, @isTextareaFocused, group,
      isPostLoading, conversation} = options

    allowedPanels ?= RxObservable.of [
      'text', 'gifs', 'image'
    ]
    @imageData = new RxBehaviorSubject null
    @hasText = new RxBehaviorSubject false
    @isTextareaFocused ?= new RxBehaviorSubject false
    selectionStart = new RxBehaviorSubject 0
    selectionEnd = new RxBehaviorSubject 0

    @$uploadImagePreview = new UploadImagePreview {
      @imageData
      @model
      uploadFn: @model.conversationMessage.uploadImage
      onUpload: ({key, width, height}) =>
        @message.next "![](<#{config.USER_CDN_URL}/cm/#{key}.small.jpg" +
                          " =#{width}x#{height}>)"
        @onPost()
    }

    @currentPanel = new RxBehaviorSubject 'text'
    @inputTranslateY ?= new RxReplaySubject 1

    @panels =
      text: {
        $icon: new Icon()
        icon: 'text'
        name: 'text'
        $el: new ConversationInputTextarea {
          onPost: @post
          @onResize
          @message
          selectionStart
          selectionEnd
          @isTextareaFocused
          isPostLoading
          @hasText
          @model
        }
      }
      image: {
        $icon: new Icon()
        icon: 'image'
        name: 'images'
        requireVerified: true
        onclick: -> null
        $uploadOverlay: new UploadOverlay {@model}
      }
      gifs: {
        $icon: new Icon()
        icon: 'gifs'
        name: 'gifs'
        requireVerified: true
        $el: new ConversationInputGifs {
          onPost: @post
          @message
          @model
          @currentPanel
          group
        }
      }

    @defaultPanelHeight = @panels.text.$el.getHeightPx()

    panelHeight = @currentPanel.switchMap (currentPanel) =>
      @panels[currentPanel].$el?.getHeightPx?()

    @inputTranslateY.next panelHeight.map (height) ->
      54 - height

    me = @model.user.getMe()


    @state = z.state
      currentPanel: @currentPanel
      me: me
      inputTranslateY: @inputTranslateY.switch()
      panelHeight: panelHeight
      group: group
      panels: allowedPanels.map (allowedPanels) =>
        _pick @panels, allowedPanels
      meGroupUser: meGroupUser
      conversation: conversation

  getTextarea$$: =>
    @panels.text.$el.$$textarea

  post: =>
    {me} = @state.getValue()

    post = =>
      promise = @onPost()
      @message.next ''
      @hasText.next false
      promise

    if me?.username
      post()
    else
      @model.user.requestLoginIfGuest me
      .then =>
        # SUPER HACK:
        # stream doesn't update while cache is being invalidated, for whatever
        # reason, so this waits until invalidation for login is ~done
        new Promise (resolve) ->
          setTimeout ->
            post().then resolve
          , 500

  render: =>
    {currentPanel, me, inputTranslateY, meGroupUser, conversation,
      group, panels, panelHeight} = @state.getValue()

    baseHeight = 54
    panelHeight or= @defaultPanelHeight
    scale = (panelHeight / baseHeight) or 1

    z '.z-conversation-input', {
      className: z.classKebab {
        "is-#{currentPanel}-panel": true
      }
      style:
        height: "#{panelHeight + 32}px"
    },
      z '.panel', {
        'ev-transitionend': =>
          @onResize?()
        style:
          transform: "translateY(#{inputTranslateY}px)"
      },
        @panels[currentPanel].$el

      z '.bottom-icons',  {
        className: z.classKebab {isVisible: true}
      },
        [
          _map panels, (options, panel) =>
            {$icon, icon, onclick, $uploadOverlay, requireVerified} = options
            z '.icon',
              z $icon, {
                onclick: onclick or =>
                  @currentPanel.next panel
                icon: icon
                color: if currentPanel is panel \
                       then colors.$bgText
                       else colors.$bgText54
                isTouchTarget: true
                hasRipple: true
                touchWidth: '36px'
                touchHeight: '36px'
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
                        @model.overlay.open z @$uploadImagePreview, {
                          iconName: 'send'
                        }
                  }
          z '.powered-by-giphy'
        ]
