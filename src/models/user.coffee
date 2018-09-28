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

  getById: (id) =>
    @auth.stream "#{@namespace}.getById", {id}

  getByUsername: (username) =>
    @auth.stream "#{@namespace}.getByUsername", {username}

  getPartner: =>
    @auth.stream "#{@namespace}.getPartner", {}

  setPartner: (partner) =>
    @auth.call "#{@namespace}.setPartner", {partner}

  setAvatarImage: (file) =>
    formData = new FormData()
    formData.append 'file', file, file.name

    @proxy config.API_URL + '/upload', {
      method: 'post'
      query:
        path: "#{@namespace}.setAvatarImage"
      body: formData
    }
    # this (exoid.update) doesn't actually work... it'd be nice
    # but it doesn't update existing streams
    # .then @exoid.update
    .then @exoid.invalidateAll

  getDisplayName: (user) =>
    user?.username or @l.get 'general.anonymous'
