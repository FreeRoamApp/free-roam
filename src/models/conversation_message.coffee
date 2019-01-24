id = require 'uuid'
_sortBy = require 'lodash/sortBy'
_merge = require 'lodash/merge'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

config = require '../config'

CHAT_MESSAGES_LIMIT = 50

module.exports = class ConversationMessage
  namespace: 'conversationMessages'

  constructor: ({@auth, @proxy, @exoid}) ->
    @clientChangesStream = {}

  create: (diff, localDiff) =>
    clientId = id.v4()

    @clientChangesStream[diff.conversationId]?.next(
      _merge diff, {clientId}, localDiff
    )
    ga? 'send', 'event', 'social_interaction', 'conversation_message', "#{diff.type}"

    @auth.call "#{@namespace}.create", _merge diff, {clientId}
    .catch (err) ->
      console.log 'err', err

  # hacky: without this, when leaving a conversation, changing browser tabs,
  # then coming back and going back to conversation, the client-created
  # messages will show for a split-second before the rest load in
  # resetClientChangesStream: (conversationId) =>
  #   @clientChangesStream[conversationId] = null

  deleteById: (id) =>
    @auth.call "#{@namespace}.deleteById", {id}, {
      invalidateAll: true
    }

  deleteAllByGroupIdAndUserId: (groupId, userId, {duration} = {}) =>
    @auth.call "#{@namespace}.deleteAllByGroupIdAndUserId", {
      groupId, userId, duration
    }, {invalidateAll: true}

  getAllByConversationId: (conversationId, options = {}) =>
    {minId, maxId, isStreamed} = options
    # buffer 0 so future streams don't try to add the client changes
    # (causes smooth scroll to bottom in conversations)
    @clientChangesStream[conversationId] ?= new RxReplaySubject(0)

    options = {
      initialSortFn: ((items) -> _sortBy items, 'time')
      limit: CHAT_MESSAGES_LIMIT
      clientChangesStream: if isStreamed \
                           then @clientChangesStream[conversationId]
                           else null
      isStreamed: isStreamed
    }

    @auth.stream "#{@namespace}.getAllByConversationId", {
      conversationId
      minId
      maxId
      isStreamed
    }, options

  getLastTimeByMeAndConversationId: (conversationId) =>
    @auth.stream "#{@namespace}.getLastTimeByMeAndConversationId", {
      conversationId
    }

  unsubscribeByConversationId: (conversationId) =>
    @auth.call "#{@namespace}.unsubscribeByConversationId", {conversationId}
    @exoid.invalidate "#{@namespace}.getAllByConversationId", {
      conversationId
      maxId: undefined
      isStreamed: true
    }

  uploadImage: (file) =>
    formData = new FormData()
    formData.append 'file', file, file.name

    @proxy config.API_URL + '/upload', {
      method: 'post'
      query:
        path: "#{@namespace}.uploadImage"
      body: formData
    }
    .then (response) =>
      @exoid.invalidateAll()
      response
