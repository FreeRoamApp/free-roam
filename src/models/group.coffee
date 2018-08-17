config = require '../config'

module.exports = class Group
  namespace: 'groups'

  constructor: ({@auth}) -> null

  create: ({name, description, badgeId, background, mode}) =>
    @auth.call "#{@namespace}.create", {
      name, description, badgeId, background, mode
    }, {invalidateAll: true}

  getAll: ({filter, language, embed} = {}) =>
    embed ?= ['conversations', 'star', 'userCount']
    @auth.stream "#{@namespace}.getAll", {filter, language, embed}

  getAllByUserUuid: (userUuid, {embed} = {}) =>
    embed ?= ['meGroupUser', 'conversations', 'star', 'userCount']
    @auth.stream "#{@namespace}.getAllByUserUuid", {userUuid, embed}

  getByUuid: (uuid, {autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getByUuid", {uuid, autoJoin}

  getById: (id, {autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getById", {id, autoJoin}

  getDefaultGroup: ({autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getById", {id: 'free-roam', autoJoin}

  getDefault: ({autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getDefault", {autoJoin}

  getAllChannelsByUuid: (id) =>
    @auth.stream "#{@namespace}.getAllChannelsByUuid", {uuid}

  joinByUuid: (uuid) =>
    @auth.call "#{@namespace}.joinByUuid", {uuid}, {
      invalidateAll: true
    }

  leaveByUuid: (uuid) =>
    @auth.call "#{@namespace}.leaveByUuid", {uuid}, {
      invalidateAll: true
    }

  inviteByUuid: (uuid, {userUuids}) =>
    @auth.call "#{@namespace}.inviteByUuid", {uuid, userUuids}, {invalidateAll: true}

  sendNotificationByUuid: (uuid, {title, description, pathKey}) =>
    @auth.call "#{@namespace}.sendNotificationByUuid", {
      uuid, title, description, pathKey
      }, {invalidateAll: true}

  updateByUuid: (uuid, {name, description, badgeId, background, mode}) =>
    @auth.call "#{@namespace}.updateByUuid", {
      uuid, name, description, badgeId, background, mode
    }, {invalidateAll: true}

  getDisplayName: (group) ->
    group?.name or 'Nameless'

  getPath: (group, key, {replacements, router, language}) ->
    unless router
      return '/'
    subdomain = router.getSubdomain()

    replacements ?= {}
    replacements.groupUuid = group?.id or group?.uuid

    path = router.get key, replacements, {language}
    if subdomain is group?.id
      path = path.replace "/#{group?.id}", ''
    path

  goPath: (group, key, {replacements, router, language}) ->
    subdomain = router.getSubdomain()

    replacements ?= {}
    replacements.groupUuid = group?.id or group?.uuid

    path = router.get key, replacements, {language}
    if subdomain is group?.id
      path = path.replace "/#{group?.id}", ''
    router.goPath path
