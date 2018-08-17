z = require 'zorium'
Environment = require '../../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

DEFAULT_TEXTAREA_HEIGHT = 54

module.exports = class ConversationInputTextarea
  constructor: (options) ->
    {@message, @onPost, @onResize, @isTextareaFocused
      @hasText, @model, isPostLoading, @selectionStart, @selectionEnd} = options

    @$sendIcon = new Icon()

    @isTextareaFocused ?= new RxBehaviorSubject false
    @textareaHeight = new RxBehaviorSubject DEFAULT_TEXTAREA_HEIGHT

    @state = z.state
      isPostLoading: isPostLoading
      textareaHeight: @textareaHeight
      hasText: @hasText

  afterMount: (@$$el) =>
    @$$textarea = @$$el.querySelector('#textarea')
    @$$textarea?.value = @message.getValue()
    @$$textarea?.setSelectionRange(
      @selectionStart.getValue(), @selectionEnd.getValue()
    )

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
    {hasText, textareaHeight, isPostLoading} = @state.getValue()

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
            unless Environment.isNativeApp config.GAME_KEY
              @model.window.pauseResizing()
          ontouchend: (e) =>
            isFocused = e.target is document.activeElement
            # weird bug causes textarea to sometimes not focus
            unless isFocused
              e?.target.focus()
          onfocus: =>
            unless Environment.isNativeApp config.GAME_KEY
              @model.window.pauseResizing()
            clearTimeout @blurTimeout
            setImmediate =>
              @isTextareaFocused.next true
            @onResize?()
          onblur: (e) =>
            @blurTimeout = setTimeout =>
              isFocused = e.target is document.activeElement
              unless isFocused
                unless Environment.isNativeApp config.GAME_KEY
                  @model.window.resumeResizing()
                setImmediate =>
                  @isTextareaFocused.next false


        z '.right-icons',
          z '.send-icon', {
            onclick: @postMessage
          },
            z @$sendIcon,
              icon: 'send'
              hasRipple: true
              color: if hasText and not isPostLoading \
                     then colors.$tertiary900Text
                     else colors.$tertiary900Text54
