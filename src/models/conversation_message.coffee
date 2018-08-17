uuid = require 'uuid'
_sortBy = require 'lodash/sortBy'
_merge = require 'lodash/merge'
_cloneDeep = require 'lodash/cloneDeep'
_defaults = require 'lodash/defaults'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject

config = require '../config'

CHAT_MESSAGES_LIMIT = 50

module.exports = class ConversationMessage
  namespace: 'conversationMessages'

  constructor: ({@auth, @proxy, @exoid}) ->
    @clientChangesStream = {}

  create: (diff, localDiff) =>
    clientUuid = uuid.v4()

    @clientChangesStream[diff.conversationUuid]?.next(
      _merge diff, {clientUuid}, localDiff
    )
    ga? 'send', 'event', 'social_interaction', 'conversation_message', "#{diff.type}"

    @auth.call "#{@namespace}.create", _merge diff, {clientUuid}
    .catch (err) ->
      console.log 'err', err

  # hacky: without this, when leaving a conversation, changing browser tabs,
  # then coming back and going back to conversation, the client-created
  # messages will show for a split-second before the rest load in
  # resetClientChangesStream: (conversationUuid) =>
  #   @clientChangesStream[conversationUuid] = null

  deleteByUuid: (uuid) =>
    @auth.call "#{@namespace}.deleteByUuid", {uuid}, {
      invalidateAll: true
    }

  deleteAllByGroupUuidAndUserUuid: (groupUuid, userUuid, {duration} = {}) =>
    @auth.call "#{@namespace}.deleteAllByGroupUuidAndUserUuid", {
      groupUuid, userUuid, duration
    }, {invalidateAll: true}

  getAllByConversationUuid: (conversationUuid, options = {}) =>
    {minUuid, maxUuid, isStreamed} = options
    # buffer 0 so future streams don't try to add the client changes
    # (causes smooth scroll to bottom in conversations)
    @clientChangesStream[conversationUuid] ?= new RxReplaySubject(0)

    options = {
      initialSortFn: ((items) -> _sortBy items, 'time')
      limit: CHAT_MESSAGES_LIMIT
      clientChangesStream: if isStreamed \
                           then @clientChangesStream[conversationUuid]
                           else null
      isStreamed: isStreamed
    }

    @auth.stream "#{@namespace}.getAllByConversationUuid", {
      conversationUuid
      minUuid
      maxUuid
      isStreamed
    }, options

  getLastTimeByMeAndConversationUuid: (conversationUuid) =>
    @auth.stream "#{@namespace}.getLastTimeByMeAndConversationUuid", {
      conversationUuid
    }

  unsubscribeByConversationUuid: (conversationUuid) =>
    @auth.call "#{@namespace}.unsubscribeByConversationUuid", {conversationUuid}
    @exoid.invalidate "#{@namespace}.getAllByConversationUuid", {
      conversationUuid
      maxUuid: undefined
      isStreamed: true
    }

  uploadImage: (file) =>
    formData = new FormData()
    formData.append 'file', file, file.name

    @proxy config.API_URL + '/upload', {
      method: 'post'
      qs:
        path: "#{@namespace}.uploadImage"
      body: formData
    }
    .then (response) =>
      @exoid.invalidateAll()
      response
