_defaults = require 'lodash/defaults'

config = require '../config'

module.exports = class Thread
  namespace: 'threads'

  constructor: ({@auth, @l, @group, @proxy, @exoid}) -> null

  upsert: (options) =>
    ga? 'send', 'event', 'social_interaction', 'thread', options.thread.category
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}

  getAll: (options = {}) =>
    {groupId, category, sort, skip, maxId,
      limit, ignoreCache} = options
    @auth.stream "#{@namespace}.getAll", {
      groupId, category, skip, maxId, limit, sort
    }, {ignoreCache}

  getById: (id, {ignoreCache} = {}) =>
    @auth.stream "#{@namespace}.getById", {id}, {ignoreCache}

  getBySlug: (slug, {ignoreCache} = {}) =>
    @auth.stream "#{@namespace}.getBySlug", {
      slug
    }, {ignoreCache}

  updateById: (id, diff) =>
    @auth.call "#{@namespace}.updateById", _defaults(diff, {id}), {
      invalidateAll: true
    }

  deleteById: (id) =>
    @auth.call "#{@namespace}.deleteById", {id}, {
      invalidateAll: true
    }

  pinById: (id) =>
    @auth.call "#{@namespace}.pinById", {id}, {
      invalidateAll: true
    }

  unpinById: (id) =>
    @auth.call "#{@namespace}.unpinById", {id}, {
      invalidateAll: true
    }

  getPath: (thread, group, router) ->
    if thread?.slug is 'how-to-boondock' # TODO: all guides
      router.get 'guide', {
        slug: thread?.slug
      }
    else
      @group.getPath group, 'groupThread', {
        router
        replacements:
          slug: thread?.slug
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

  hasPermission: (thread, user, {level} = {}) ->
    userId = user?.id
    level ?= 'member'

    unless userId and thread
      return false

    return switch level
      when 'admin'
      then thread.userId is userId
      # member
      else thread.userIds?.indexOf(userId) isnt -1
