z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

DEFAULT_TEXTAREA_HEIGHT = 52

module.exports = class ConversationInputTextarea
  constructor: (options) ->
    {@message, @onPost, @onResize, @isTextareaFocused
      @hasText, @model, isPostLoading, @selectionStart, @selectionEnd} = options

    @$sendIcon = new Icon()

    @isTextareaFocused ?= new RxBehaviorSubject false
    @textareaHeight = new RxBehaviorSubject DEFAULT_TEXTAREA_HEIGHT

    @state = z.state
      isPostLoading: isPostLoading
      isTextareaFocused: @isTextareaFocused
      textareaHeight: @textareaHeight
      hasText: @hasText

  afterMount: (@$$el) =>
    @$$textarea = @$$el.querySelector('#textarea')
    @$$textarea?.value = @message.getValue()
    @$$textarea?.setSelectionRange(
      @selectionStart.getValue(), @selectionEnd.getValue()
    )
    if Environment.isIos()
      # ios focuses on setSelectionRange
      @$$textarea?.blur()

  beforeUnmount: =>
    @selectionStart.next @$$textarea?.selectionStart
    @selectionEnd.next @$$textarea?.selectionEnd

  setMessageFromEvent: (e) =>
    e or= window.event
    @setMessage e.target.value

  setMessage: (message) =>
    currentValue = @message.getValue()
    if not currentValue and message
      @hasText.next true
    else if currentValue and not message
      @hasText.next false
    @message.next message

  postMessage: (e) =>
    {isPostLoading} = @state.getValue()
    unless isPostLoading
      $$textarea = @$$el.querySelector('#textarea')

      unless Environment.isIos()
        # not sure why this is here, but it causes the pause/resume resizing
        # to bug out on ios
        $$textarea?.focus()

      $$textarea?.style.height = "#{DEFAULT_TEXTAREA_HEIGHT}px"
      @textareaHeight.next DEFAULT_TEXTAREA_HEIGHT
      $$textarea?.value = ''
      @onPost?()
      .then (response) =>
        if response?.rewards
          if e?.clientX
            x = e?.clientX
            y = e?.clientY
          else
            boundingRect = @$$el?.getBoundingClientRect?()
            x = boundingRect?.left
            y = boundingRect?.top
          @model.earnAlert.show {rewards: response?.rewards, x, y}

  resizeTextarea: (e) =>
    {textareaHeight} = @state.getValue()
    $$textarea = e.target
    $$textarea.style.height = "#{DEFAULT_TEXTAREA_HEIGHT}px"
    newHeight = $$textarea.scrollHeight
    $$textarea.style.height = "#{newHeight}px"
    $$textarea.scrollTop = newHeight
    unless textareaHeight is newHeight
      @textareaHeight.next newHeight
      @onResize?()

  getHeightPx: =>
    @textareaHeight.map (height) ->
      Math.min height, 150 # max height in css

  render: =>
    {hasText, textareaHeight, isPostLoading,
      isTextareaFocused} = @state.getValue()

    z '.z-conversation-input-textarea',
        z 'textarea.textarea',
          id: 'textarea'
          key: 'conversation-input-textarea'
          # # for some reason necessary on iOS to get it to focus properly
          # onclick: (e) ->
          #   setTimeout ->
          #     e?.target?.focus()
          #   , 0
          style:
            height: "#{textareaHeight}px"
          placeholder: @model.l.get 'conversationInputTextArea.hintText'
          onkeydown: (e) ->
            if e.keyCode is 13 and not e.shiftKey
              e.preventDefault()
          onkeyup: (e) =>
            if e.keyCode is 13 and not e.shiftKey
              e.preventDefault()
              @postMessage()
          oninput: (e) =>
            @resizeTextarea e
            @setMessageFromEvent e
          ontouchstart: (e) =>
            if Environment.isIos() and not Environment.isNativeApp 'freeroam'
              @model.window.pauseResizing()
          ontouchend: (e) ->
            isFocused = e.target is document.activeElement
            # weird bug causes textarea to sometimes not focus
            if not isFocused and not Environment.isIos()
              e?.target.focus()
          onfocus: =>
            if Environment.isIos() and not Environment.isNativeApp 'freeroam'
              @model.window.pauseResizing()
            clearTimeout @blurTimeout
            setTimeout => # FIXME FIXME: breaks ios?
              @isTextareaFocused.next true
            , 0
            @onResize?()
          onblur: (e) =>
            @blurTimeout = setTimeout =>
              isFocused = e.target is document.activeElement
              unless isFocused
                if Environment.isIos() and not Environment.isNativeApp 'freeroam'
                  # give time for keyboard anim to finish
                  setTimeout =>
                    @model.window.resumeResizing()
                  , 100
                setTimeout =>
                  @isTextareaFocused.next false
                , 0
            , 0


        z '.right-icons', {
          className: z.classKebab {isVisible: isTextareaFocused}
        },
          z '.send-icon', {
            onclick: @postMessage
          },
            z @$sendIcon,
              icon: 'send'
              hasRipple: true
              color: if hasText and not isPostLoading \
                     then colors.$bgText
                     else colors.$bgText54
