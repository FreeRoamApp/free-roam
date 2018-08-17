z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_last = require 'lodash/last'
_first = require 'lodash/first'
_isEmpty = require 'lodash/isEmpty'
_debounce = require 'lodash/debounce'
_flatten = require 'lodash/flatten'
_uniqBy = require 'lodash/uniqBy'
_pick = require 'lodash/pick'
Environment = require '../../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/merge'
require 'rxjs/add/observable/never'
require 'rxjs/add/operator/share'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'

Spinner = require '../spinner'
Base = require '../base'
FormattedText = require '../formatted_text'
PrimaryButton = require '../primary_button'
ConversationInput = require '../conversation_input'
ConversationMessage = require '../conversation_message'
config = require '../../config'

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap.js'
  require './index.styl'

# we don't give immediate feedback for post (waits for cache invalidation and
# refetch), don't want users to post twice
MAX_POST_MESSAGE_LOAD_MS = 5000 # 5s
MAX_CHARACTERS = 500
MAX_LINES = 20
SCROLL_MAX_WAIT_MS = 100
FIVE_MINUTES_MS = 60 * 5 * 1000
SCROLL_MESSAGE_LOAD_COUNT = 20
DELAY_BETWEEN_LOAD_MORE_MS = 250

module.exports = class Conversation extends Base
  constructor: (options) ->
    {@model, @router, @error, @conversation, isActive, @overlay$,
      selectedProfileDialogUser, @scrollYOnly, @isGroup, isLoading, @onScrollUp,
      @onScrollDown, @minUuid, hasBottomBar, group} = options

    isLoading ?= new RxBehaviorSubject false
    @isPostLoading = new RxBehaviorSubject false
    isActive ?= new RxBehaviorSubject false
    me = @model.user.getMe()
    @conversation ?= new RxBehaviorSubject null
    @error = new RxBehaviorSubject null

    @isPaused = new RxBehaviorSubject false

    conversationAndMeAndminUuid = RxObservable.combineLatest(
      @conversation
      me
      @minUuid or RxObservable.of null
      (vals...) -> vals
    )

    # not putting in state because re-render is too slow on type
    @message = new RxBehaviorSubject ''
    @resetMessageBatches = new RxBehaviorSubject null

    lastConversationUuid = null
    @canLoadMore = true
    @isFirstLoad = true

    loadedMessages = conversationAndMeAndminUuid.switchMap (resp) =>
      [conversation, me, minUuid] = resp

      if minUuid
        @state.set hasLoadedAllNewMessages: false

      if lastConversationUuid isnt conversation?.uuid
        isLoading.next true

      lastConversationUuid = conversation?.uuid

      @messageBatchesStreams = new RxReplaySubject(1)
      @messageBatchesStreamCache = []
      @prependMessagesStream @getMessagesStream {minUuid}

      @messageBatchesStreams.switch()
      .map (messageBatches) =>
        isLoading.next false
        @$$loadingSpinner?.style.display = 'none'
        @state.set isLoaded: true
        @iScrollContainer?.refresh()

        if minUuid and @isFirstLoad
          @isFirstLoad = false
          # scroll to top
          setTimeout =>
            if Environment.isiOS {userAgent: navigator.userAgent}
              @messages.scrollTop = @$$messages.scrollHeight + @$$messages.offsetHeight - 1
            else
              @$$messages.scrollTop = 1 # if it's 0, it'll load more msgs
          , 100

        messageBatches
      .catch (err) ->
        console.log err
        RxObservable.of []
    .share()

    messageBatches = RxObservable.merge @resetMessageBatches, loadedMessages

    @groupUser = if group \
                then group.map (group) -> group?.meGroupUser
                else RxObservable.of null

    groupUserAndConversation = RxObservable.combineLatest(
      @groupUser, @conversation, (vals...) -> vals
    )

    @inputTranslateY = new RxReplaySubject 1
    @isTextareaFocused = new RxBehaviorSubject false

    @$loadingSpinner = new Spinner()
    @$joinButton = new PrimaryButton()
    @$conversationInput = new ConversationInput {
      @model
      @router
      @message
      @isTextareaFocused
      @isPostLoading
      @overlay$
      @inputTranslateY
      @conversation
      group: group
      meGroupUser: @groupUser
      onPost: @postMessage
      allowedPanels: groupUserAndConversation.map ([groupUser, conversation]) =>
        if conversation?.groupUuid
          panels = ['text', 'stickers']
          meGroupUser = groupUser
          permissions = ['sendImage']
          channelUuid = conversation.uuid
          hasImagePermission = @model.groupUser.hasPermission {
            meGroupUser, permissions, channelUuid
          }
          if hasImagePermission
            panels = panels.concat ['image', 'gifs']

          permissions = ['sendAddon']
          hasAddonPermission = @model.groupUser.hasPermission {
            meGroupUser, permissions, channelUuid
          }
          if hasAddonPermission
            panels = panels.concat ['addons']

          panels
        else
          ['text', 'stickers', 'image', 'gifs', 'addons']
    }

    messageBatchesAndMeAndBlockedUserUuids = RxObservable.combineLatest(
      messageBatches
      me
      @model.userBlock.getAllIds()
      (vals...) -> vals
    )

    @state = z.state
      me: me
      isLoading: isLoading
      isActive: isActive
      isPostLoading: @isPostLoading
      hasBottomBar: hasBottomBar
      hasLoadedAllNewMessages: true
      error: null
      conversation: @conversation
      inputTranslateY: @inputTranslateY.switch()
      group: group
      groupUser: @groupUser
      isJoinLoading: false
      isLoaded: false

      messageBatches: messageBatchesAndMeAndBlockedUserUuids
      .map ([messageBatches, me, blockedUserUuids]) =>
        if messageBatches
          _map messageBatches, (messages) =>
            prevMessage = null
            _filter _map messages, (message) =>
              unless message
                return
              isBlocked = @model.userBlock.isBlocked(
                blockedUserUuids, message?.userUuid
              )
              if isBlocked
                return
              isRecent = new Date(message?.time) - new Date(prevMessage?.time) <
                          FIVE_MINUTES_MS
              isGrouped = message.userUuid is prevMessage?.userUuid and isRecent
              isMe = message.userUuid is me.uuid
              uuid = message.uuid or message.clientUuid
              # if we get this in conversationmessasge, there's a flicker for
              # state to get set
              bodyCacheKey = "#{message.clientUuid}:text"
              messageCacheKey = "#{uuid}:#{message.lastUpdateTime}:message"

              $body = @getCached$ bodyCacheKey, FormattedText, {
                @model, @router, text: message.body, selectedProfileDialogUser
                mentionedUsers: message.mentionedUsers
                useThumbnails: true
              }
              $el = @getCached$ messageCacheKey, ConversationMessage, {
                message, @model, @router, @overlay$, isMe, @isTextareaFocused,
                isGrouped, selectedProfileDialogUser, $body,
                @messageBatchesStreams
              }
              prevMessage = message
              {$el, isGrouped, timeUuid: message.timeUuid, uuid}

  afterMount: (@$$el) =>
    @$$loadingSpinner = @$$el?.querySelector('.loading')
    @$$messages = @$$el?.querySelector('.messages')
    # use iscroll on ios...
    if Environment.isiOS {userAgent: navigator.userAgent}
      checkIsReady = =>
        @$$messages = @$$el?.querySelector('.messages')
        if @$$messages and @$$messages.clientWidth
          @initIScroll @$$messages
        else
          setTimeout checkIsReady, 1000

      checkIsReady()
    else
      @debouncedScrollListener = _debounce @scrollListener, 20, {
        maxWait: SCROLL_MAX_WAIT_MS
        trailing: true
      }
      @$$messages?.addEventListener 'scroll', @debouncedScrollListener

    prevConversation = null
    @disposable = @conversation.subscribe (newConversation) =>
      @model.portal.call 'push.setContextId', {
        contextId: newConversation?.uuid
      }
      # server doesn't need to push us new updates
      if prevConversation and prevConversation.uuid isnt newConversation.uuid
        @model.conversationMessage.unsubscribeByConversationUuid prevConversation.uuid

      prevConversation = newConversation

  beforeUnmount: =>
    super()

    {conversation} = @state.getValue()
    if conversation
      @model.conversationMessage.unsubscribeByConversationUuid conversation?.uuid

    @isFirstLoad = true

    @disposable.unsubscribe()

    @isPaused.next false
    @iScrollContainer?.destroy()

    @$$messages?.removeEventListener 'scroll', @debouncedScrollListener
    @$$loadingSpinner?.style.display = 'block'

    # to update conversations page, etc...
    # TODO: should update via streaming or just ignore cache?
    unless @isGroup
    #   # race condition without timeout.
    #   # new page tries to get new exoid stuff, but it gets cleared at same
    #   # exact time. caused an issue of leaving event page back to home,
    #   # and home had no responses / empty streams / unobserved streams
    #   # for group data
      setImmediate =>
        @model.exoid.invalidateAll()
    @resetMessageBatches.next [[]]
    setTimeout =>
      @state.set isLoaded: false, hasLoadedAllNewMessages: true
    , 0

    @model.portal.call 'push.setContextId', {
      contextId: 'empty'
    }


    # hacky: without this, when leaving a conversation, changing browser tabs,
    # then coming back and going back to conversation, the client-created
    # messages will show for a split-second before the rest load in.
    # but WITH this, leaving a conversation and coming back to it sometimes
    # causes new messages to not post FIXME FIXME
    # @model.conversationMessage.resetClientChangesStream conversation?.uuid

  initIScroll: =>
    @iScrollContainer = new IScroll @$$messages, {
      scrollX: false
      scrollY: true
      # eventPassthrough: true
      click: true
      bounce: false
      deceleration: 0.0006
      useTransition: false
      isReversed: true
    }

    # the scroll listener in IScroll (iscroll-probe.js) is really slow
    isScrolling = false
    @iScrollContainer.on 'scrollStart', =>
      isScrolling = true
      update = =>
        @iScrollListener()
        if isScrolling
          window.requestAnimationFrame update
      update()

    @iScrollContainer.on 'scrollEnd', =>
      isScrolling = false

  getMessagesStream: ({minUuid, maxUuid, isStreamed} = {}) =>
    isStreamed ?= not maxUuid and not minUuid
    conversationAndIsPaused = RxObservable.combineLatest(
      @conversation
      @isPaused
      (vals...) -> vals
    )
    # TODO: might be better to have the isPaused somewhere else.
    # have 1 obs with all messages, and 1 that's paused, and get the diff
    # in count to show how many new messages
    conversationAndIsPaused.switchMap (result) =>
      [conversation, isPaused] = result
      if isPaused and not maxUuid
        RxObservable.never()
      else if conversation
        @model.conversationMessage.getAllByConversationUuid conversation.uuid, {
          minUuid
          maxUuid
          # don't stream old message batches
          isStreamed
        }
      else
        RxObservable.of null

  iScrollListener: =>
    isBottom = @iScrollContainer.y is 0
    isTop = @iScrollContainer.y is @iScrollContainer.maxScrollY

    if isBottom and @isPaused.getValue()
      @isPaused.next false
    else if isTop and @isPaused.getValue()
      @isPaused.next false
    else if not @isPaused.getValue()
      @isPaused.next true

    maxScrollY = @iScrollContainer.maxScrollY or @$$messages.offsetHeight
    scrollY = maxScrollY - @iScrollContainer.y
    @handleScroll(
      Math.abs(scrollY), @iScrollContainer.y, @iScrollContainer.directionY
    )

  scrollListener: =>
    scrollTop = @$$messages.scrollTop
    scrollHeight = @$$messages.scrollHeight
    offsetHeight = @$$messages.offsetHeight
    fromBottom = scrollHeight - offsetHeight - scrollTop


    # safari treats these different with flex-direction: column-reverse
    isSafari = navigator.userAgent?.match /^((?!chrome|android).)*safari/i
    if isSafari
      # scrollTopTmp = scrollTop
      # scrollTop = fromBottom
      fromBottom = Math.abs scrollTop
      scrollTop = scrollTop + (scrollHeight - offsetHeight)

    direction = if scrollTop < @lastFromTopPx \
                then 1
                else if scrollTop > @lastFromTopPx
                then -1
                else 0

    @handleScroll scrollTop, fromBottom, direction

  handleScroll: (fromTopPx, fromBottomPx, direction) =>
    notNearTop = fromTopPx > 50

    if notNearTop and direction is 1
      @onScrollUp?()
    else if notNearTop and direction is -1
      @onScrollDown?()

    if @canLoadMore and fromTopPx is 0
      @loadOlder()
    else if @canLoadMore and fromBottomPx is 0
      {hasLoadedAllNewMessages} = @state.getValue()
      unless hasLoadedAllNewMessages
        @loadNewer()

    @lastFromTopPx = fromTopPx

  loadOlder: =>
    @canLoadMore = false

    # don't re-render or set state since it's slow with all of the conversation
    # messages
    @$$loadingSpinner.style.display = 'block'

    {messageBatches} = @state.getValue()
    maxUuid = messageBatches?[0]?[0]?.timeUuid
    messagesStream = @getMessagesStream {maxUuid}
    @prependMessagesStream messagesStream

    messagesStream.take(1).toPromise()
    .then =>
      setTimeout (=> @canLoadMore = true), DELAY_BETWEEN_LOAD_MORE_MS

      @$$loadingSpinner.style.display = 'none'

  loadNewer: (isStreamed) =>
    @canLoadMore = false

    # don't re-render or set state since it's slow with all of the conversation
    # messages
    @$$loadingSpinner.style.display = 'block'

    {messageBatches, hasLoadedAllNewMessages} = @state.getValue()
    minUuid = _last(_last(messageBatches))?.timeUuid
    messagesStream = @getMessagesStream {minUuid, isStreamed}
    @appendMessagesStream messagesStream

    previousScrollHeight = @$$messages.scrollHeight

    messagesStream.take(1).toPromise()
    .then (messages) =>
      setTimeout (=> @canLoadMore = true), DELAY_BETWEEN_LOAD_MORE_MS

      # should be caught up now
      if messages?.length < 10 and not hasLoadedAllNewMessages
        @state.set {hasLoadedAllNewMessages: true}
        # HACK. need to wait until messageBatches is updated so it can grab
        # the new minUuid
        setTimeout =>
          @loadNewer isStreamed = true
        , 500

      # scroll to previous point
      window.requestAnimationFrame =>
        @$$messages.scrollTop =
            @$$messages.scrollHeight - (@$$messages.scrollHeight - previousScrollHeight)

      @$$loadingSpinner.style.display = 'none'


  prependMessagesStream: (messagesStream) =>
    @messageBatchesStreamCache = [messagesStream].concat(
      @messageBatchesStreamCache
    )
    @messageBatchesStreams.next RxObservable.combineLatest(
      @messageBatchesStreamCache, (messageBatches...) ->
        messageBatches
    )

  appendMessagesStream: (messagesStream) =>
    @messageBatchesStreamCache = @messageBatchesStreamCache.concat(
      [messagesStream]
    )
    @messageBatchesStreams.next RxObservable.combineLatest(
      @messageBatchesStreamCache, (messageBatches...) ->
        messageBatches
    )

  jumpToNew: =>
    messagesStream = @getMessagesStream()
    @messageBatchesStreamCache = [messagesStream]
    @messageBatchesStreams.next RxObservable.combineLatest(
      @messageBatchesStreamCache, (messageBatches...) ->
        messageBatches
    )
    @state.set hasLoadedAllNewMessages: true

  postMessage: =>
    {me, conversation, isPostLoading} = @state.getValue()

    messageBody = @message.getValue()

    if not isPostLoading and messageBody
      @isPostLoading.next true

      type = if conversation?.group?.type is 'public' \
             then 'public'
             else if conversation?.groupUuid
             then 'group'
             else 'private'
      ga? 'send', 'event', 'conversation_message', 'post', type

      @model.conversationMessage.create {
        body: messageBody
        conversationUuid: conversation?.uuid
        userUuid: me?.uuid
      }, {user: me, time: Date.now()}
      .then (response) =>
        # @model.user.emit('conversationMessage').catch log.error
        @isPostLoading.next false
        response
      .catch =>
        @isPostLoading.next false
    else
      Promise.resolve null # reject here?

  join: =>
    {me, group} = @state.getValue()
    @state.set isJoinLoading: true

    @model.signInDialog.openIfGuest me
    .then =>
      unless @model.cookie.get 'isPushTokenStored'
        @model.pushNotificationSheet.open()
      Promise.all _filter [
        @model.group.joinByUuid group.uuid
        if group.star
          @model.userFollower.followByUserUuid group.star?.user?.uuid
      ]
      .then =>
        # just in case...
        setTimeout =>
          @state.set isJoinLoading: false
        , 1000
        @groupUser.take(1).subscribe =>
          @state.set isJoinLoading: false
    .catch =>
      @state.set isJoinLoading: false

  render: =>
    {me, isLoading, message, hasLoadedAllNewMessages,
      isLoaded, messageBatches, conversation, group, inputTranslateY,
      groupUser, isJoinLoading, hasBottomBar} = @state.getValue()

    z '.z-conversation', {
      className: z.classKebab {hasBottomBar}
      onclick: (e) =>
        if @isTextareaFocused.getValue() and Environment.isiOS() and
            e?.target isnt @$conversationInput.getTextarea$$()
          document.activeElement.blur()
    },
      # toggled with vanilla js (non-vdom for perf)
      z '.loading', {
        key: 'conversation-messages-loading-spinner'
      },
        @$loadingSpinner
      # hide messages until loaded to prevent showing the scrolling
      z '.messages', {
        key: 'conversation-messages'
        style:
          transform: "translateY(#{inputTranslateY}px)"
      },
        z '.messages-inner',
          if messageBatches and not isLoading
            _map messageBatches, (messageBatch) ->
              z '.message-batch', {
                className: z.classKebab {isLoaded}
                key: "message-batch-#{messageBatch?[0]?.uuid}"
              },
                _map messageBatch, ({$el, isGrouped}, i) ->
                  [
                      if i and not isGrouped
                        z '.divider'
                      z $el
                  ]

      if conversation?.groupUuid and groupUser and not groupUser.userUuid
        z '.bottom.is-gate',
          z '.text',
            @model.l.get 'conversation.joinMessage', {
              replacements:
                name: @model.user.getDisplayName group.star?.user
            }
          z @$joinButton,
            text: if isJoinLoading \
                  then @model.l.get 'general.loading'
                  else @model.l.get 'groupInfo.joinButtonText'
            onclick: @join
      else
        z '.bottom',
          unless hasLoadedAllNewMessages
            z '.jump-new', {
              onclick: =>
                @jumpToNew()
            },
              @model.l.get 'conversations.jumpNew'
          @$conversationInput
