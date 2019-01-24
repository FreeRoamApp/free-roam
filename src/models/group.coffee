module.exports = class Group
  namespace: 'groups'

  constructor: ({@auth}) -> null

  create: ({name, description, mode}) =>
    @auth.call "#{@namespace}.create", {
      name, description, mode
    }, {invalidateAll: true}

  getAll: ({filter, language, embed} = {}) =>
    embed ?= ['conversations', 'star', 'userCount']
    @auth.stream "#{@namespace}.getAll", {filter, language, embed}

  getAllByUserId: (userId, {embed} = {}) =>
    embed ?= ['meGroupUser', 'conversations', 'star', 'userCount']
    @auth.stream "#{@namespace}.getAllByUserId", {userId, embed}

  getById: (id, {autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getById", {id, autoJoin}

  getBySlug: (slug, {autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getBySlug", {slug, autoJoin}

  getDefaultGroup: ({autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getBySlug", {slug: 'boondocking', autoJoin}

  getDefault: ({autoJoin} = {}) =>
    @auth.stream "#{@namespace}.getDefault", {autoJoin}

  getAllConversationsById: (id) =>
    @auth.stream "#{@namespace}.getAllConversationsById", {id}

  joinById: (id) =>
    @auth.call "#{@namespace}.joinById", {id}, {
      invalidateAll: true
    }

  leaveById: (id) =>
    @auth.call "#{@namespace}.leaveById", {id}, {
      invalidateAll: true
    }

  inviteById: (id, {userIds}) =>
    @auth.call "#{@namespace}.inviteById", {id, userIds}, {invalidateAll: true}

  sendNotificationById: (id, {title, description, pathKey}) =>
    @auth.call "#{@namespace}.sendNotificationById", {
      id, title, description, pathKey
      }, {invalidateAll: true}

  updateById: (id, {name, description, mode}) =>
    @auth.call "#{@namespace}.updateById", {
      id, name, description, mode
    }, {invalidateAll: true}

  getDisplayName: (group) ->
    group?.name or 'Nameless'

  getPath: (group, key, {replacements, router, language}) ->
    unless router
      return '/'
    subdomain = router.getSubdomain()

    replacements ?= {}
    replacements.groupId = group?.slug or group?.id

    path = router.get key, replacements, {language}
    if subdomain is group?.slug
      path = path.replace "/#{group?.slug}", ''
    path

  goPath: (group, key, {replacements, router, language}) ->
    subdomain = router.getSubdomain()

    replacements ?= {}
    replacements.groupId = group?.slug or group?.id

    path = router.get key, replacements, {language}
    if subdomain is group?.slug
      path = path.replace "/#{group?.slug}", ''
    router.goPath path
