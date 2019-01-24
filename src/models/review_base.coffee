config = require '../config'

module.exports = class Review
  constructor: ({@auth, @proxy, @exoid}) -> null

  upsert: (options) =>
    @auth.call "#{@namespace}.upsert", options, {invalidateAll: true}

  getAllByParentId: (parentId, options = {}) =>
    {sort, skip, maxId, limit, ignoreCache} = options
    @auth.stream "#{@namespace}.getAllByParentId", {
      parentId, skip, maxId, limit, sort
    }, {ignoreCache}

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  deleteById: (id) =>
    @auth.call "#{@namespace}.deleteById", {id}, {
      invalidateAll: true
    }

  uploadImage: (file, {onProgress}) =>
    formData = new FormData()
    formData.append 'file', file, file.name

    requestPromise = @proxy config.API_URL + '/upload', {
      method: 'post'
      beforeSend: (xhr) ->
        xhr.upload.addEventListener 'progress', onProgress, false
      query:
        path: "#{@namespace}.uploadImage"
      body: formData
    }

    requestPromise
    .then (response) =>
      @exoid.invalidateAll()
      response

  hasPermission: (review, user, {level} = {}) ->
    userId = user?.id
    level ?= 'member'

    unless userId and review
      return false

    return switch level
      when 'admin'
      then review.userId is userId
      # member
      else review.userIds?.indexOf(userId) isnt -1
