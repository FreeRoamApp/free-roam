_every = require 'lodash/every'
_find = require 'lodash/find'
_defaults = require 'lodash/defaults'
_clone = require 'lodash/clone'

config = require '../config'

module.exports = class GroupUser
  namespace: 'groupUsers'

  constructor: ({@auth}) -> null

  addRoleByGroupIdAndUserId: (groupId, userId, roleId) =>
    @auth.call "#{@namespace}.addRoleByGroupIdAndUserId", {
      userId, groupId, roleId
    }, {invalidateAll: true}

  removeRoleByGroupIdAndUserId: (groupId, userId, roleId) =>
    @auth.call "#{@namespace}.removeRoleByGroupIdAndUserId", {
      userId, groupId, roleId
    }, {invalidateAll: true}

  addXpByGroupIdAndUserId: (groupId, userId, xp) =>
    @auth.call "#{@namespace}.addXpByGroupIdAndUserId", {
      userId, groupId, xp
    }, {invalidateAll: true}

  getByGroupIdAndUserId: (groupId, userId) =>
    @auth.stream "#{@namespace}.getByGroupIdAndUserId", {groupId, userId}

  getTopByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getTopByGroupId", {groupId}

  getMeSettingsByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getMeSettingsByGroupId", {groupId}

  getOnlineCountByGroupId: (groupId) =>
    @auth.stream "#{@namespace}.getOnlineCountByGroupId", {groupId}

  updateMeSettingsByGroupId: (groupId, {globalNotifications}) =>
    @auth.call "#{@namespace}.updateMeSettingsByGroupId", {
      groupId, globalNotifications
    }

  hasPermission: ({meGroupUser, me, permissions, channelId, roles}) ->
    roles ?= meGroupUser?.roles
    isGlobalModerator = me?.flags?.isModerator or me?.username is 'austin'
    isGlobalModerator or _every permissions, (permission) ->
      _find roles, (role) ->
        channelPermissions = channelId and role.channelPermissions?[channelId]
        globalPermissions = role.globalPermissions
        permissions = _defaults(
          channelPermissions, globalPermissions, config.DEFAULT_PERMISSIONS
        )
        permissions[permission]
