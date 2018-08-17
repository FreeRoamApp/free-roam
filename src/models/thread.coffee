_defaults = require 'lodash/defaults'
_kebabCase = require 'lodash/kebabCase'

config = require '../config'

module.exports = class Thread
  namespace: 'threads'

  constructor: ({@auth, @l, @group}) -> null

  upsert: (options) =>
    ga? 'send', 'event', 'social_interaction', 'thread', options.thread.category
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}

  getAll: (options = {}) =>
    {groupUuid, category, sort, skip, maxUuid,
      limit, ignoreCache} = options
    language = @l.getLanguageStr()
    @auth.stream "#{@namespace}.getAll", {
      groupUuid, category, language, skip, maxUuid, limit, sort
    }, {ignoreCache}

  getByUuid: (uuid, {ignoreCache} = {}) =>
    language = @l.getLanguageStr()
    @auth.stream "#{@namespace}.getByUuid", {uuid, language}, {ignoreCache}

  getById: (id, {ignoreCache} = {}) =>
    language = @l.getLanguageStr()
    @auth.stream "#{@namespace}.getById", {
      id, language
    }, {ignoreCache}

  updateByUuid: (uuid, diff) =>
    @auth.call "#{@namespace}.updateByUuid", _defaults(diff, {uuid}), {
      invalidateAll: true
    }

  deleteByUuid: (uuid) =>
    @auth.call "#{@namespace}.deleteByUuid", {uuid}, {
      invalidateAll: true
    }

  pinByUuid: (uuid) =>
    @auth.call "#{@namespace}.pinByUuid", {uuid}, {
      invalidateAll: true
    }

  unpinByUuid: (uuid) =>
    @auth.call "#{@namespace}.unpinByUuid", {uuid}, {
      invalidateAll: true
    }

  getPath: (thread, group, router) ->
    console.log 'ge tpath', thread
    formattedTitle = _kebabCase thread?.data?.title
    @group.getPath group, 'groupThread', {
      router
      replacements:
        id: thread?.id
    }

  hasPermission: (thread, user, {level} = {}) ->
    userUuid = user?.uuid
    level ?= 'member'

    unless userUuid and thread
      return false

    return switch level
      when 'admin'
      then thread.userUuid is userUuid
      # member
      else thread.userUuids?.indexOf(userUuid) isnt -1
