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

  getByCode: (code) =>
    @auth.stream "#{@namespace}.getByCode", {code}

  setUsername: (username) =>
    @auth.call "#{@namespace}.setUsername", {username}, {invalidateAll: true}

  setLanguage: (language) =>
    @auth.call "#{@namespace}.setLanguage", {language}

  getAllByPlayerIdAndGameKey: (playerId, gameKey) =>
    @auth.stream "#{@namespace}.getAllByPlayerIdAndGameKey", {playerId, gameKey}

  searchByUsername: (username) =>
    @auth.call "#{@namespace}.searchByUsername", {username}

  # makeMember: =>
  #   @auth.call "#{@namespace}.makeMember", {}, {invalidateAll: true}

  setFlags: (flags) =>
    @auth.call "#{@namespace}.setFlags", flags, {invalidateAll: true}

  setFlagsById: (id, flags) =>
    @auth.call "#{@namespace}.setFlagsById", {id, flags}, {invalidateAll: true}

  requestInvite: ({clanTag, username, email, referrerId}) =>
    @auth.call "#{@namespace}.requestInvite", {
      clanTag, username, email, referrerId
    }

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
