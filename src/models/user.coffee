config = require '../config'

module.exports = class User
  namespace: 'users'

  constructor: ({@auth, @proxy, @exoid, @cookie, @l}) -> null

  getMe: =>
    @auth.stream "#{@namespace}.getMe"

  getIp: =>
    @cookie.get 'ip'

  getCountry: =>
    @auth.stream "#{@namespace}.getCountry"

  getByUuid: (uuid) =>
    @auth.stream "#{@namespace}.getByUuid", {uuid}

  getByUsername: (username) =>
    @auth.stream "#{@namespace}.getByUsername", {username}

  setAvatarImage: (file) =>
    formData = new FormData()
    formData.append 'file', file, file.name

    @proxy config.API_URL + '/upload', {
      method: 'post'
      qs:
        path: "#{@namespace}.setAvatarImage"
      body: formData
    }
    # this (exoid.update) doesn't actually work... it'd be nice
    # but it doesn't update existing streams
    # .then @exoid.update
    .then @exoid.invalidateAll

  getDisplayName: (user) =>
    user?.username or @l.get 'general.anonymous'
