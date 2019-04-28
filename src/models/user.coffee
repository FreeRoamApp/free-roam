SignInDialog = require '../components/sign_in_dialog'
config = require '../config'

module.exports = class User
  namespace: 'users'

  constructor: ({@auth, @proxy, @exoid, @cookie, @l, @overlay, @portal}) -> null

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

  search: ({query, limit}) =>
    @auth.stream "#{@namespace}.search", {query, limit}

  getPartner: =>
    @auth.stream "#{@namespace}.getPartner", {}

  setPartner: (partner) =>
    @auth.call "#{@namespace}.setPartner", {partner}

  upsert: (userDiff, {file} = {}) =>
    if file
      formData = new FormData()
      formData.append 'file', file, file.name

      @proxy config.API_URL + '/upload', {
        method: 'post'
        query:
          path: "#{@namespace}.upsert"
          body: JSON.stringify {userDiff}
        body: formData
      }
      # this (exoid.update) doesn't actually work... it'd be nice
      # but it doesn't update existing streams
      # .then @exoid.update
      .then (response) =>
        setTimeout @exoid.invalidateAll, 0
        response
    else
      @auth.call "#{@namespace}.upsert", {userDiff}, {invalidateAll: true}

  getDisplayName: (user) =>
    user?.username or @l.get 'general.anonymous'

  requestLoginIfGuest: (user) =>
    new Promise (resolve, reject) =>
      if user?.username
        resolve true
      else
        @overlay.open new SignInDialog({
          model: {@l, @auth, @overlay, @portal, user: this}
        }), {
          data: 'join'
          onComplete: resolve
          onCancel: reject
        }
