SignInOverlay = require '../components/sign_in_overlay'
config = require '../config'

module.exports = class User
  namespace: 'users'

  constructor: ({@auth, @proxy, @exoid, @cookie, @l, @overlay, @portal}) -> null

  getMe: ({embed} = {}) =>
    @auth.stream "#{@namespace}.getMe", {embed}

  getIp: =>
    @cookie.get 'ip'

  getCountry: =>
    @auth.stream "#{@namespace}.getCountry"

  getById: (id, {embed} = {}) =>
    @auth.stream "#{@namespace}.getById", {id, embed}

  getByUsername: (username, {embed} = {}) =>
    @auth.stream "#{@namespace}.getByUsername", {username, embed}

  search: ({query, limit}) =>
    @auth.stream "#{@namespace}.search", {query, limit}

  getPartner: =>
    @auth.stream "#{@namespace}.getPartner", {}

  setPartner: (partner) =>
    @auth.call "#{@namespace}.setPartner", {partner}

  unsubscribeEmail: ({userId, token}) =>
    @auth.call "#{@namespace}.unsubscribeEmail", {userId, token}

  verifyEmail: ({userId, token}) =>
    @auth.call "#{@namespace}.verifyEmail", {userId, token}

  resendVerficationEmail: =>
    @auth.call "#{@namespace}.resendVerficationEmail", {}

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
        @overlay.open new SignInOverlay({
          model: {@l, @auth, @overlay, @portal, user: this}
        }), {
          data: 'join'
          onComplete: resolve
          onCancel: reject
        }
