_every = require 'lodash/every'
_find = require 'lodash/find'
_defaults = require 'lodash/defaults'
_clone = require 'lodash/clone'

config = require '../config'

module.exports = class GroupUser
  namespace: 'groupUsers'

  constructor: ({@auth}) -> null

  addRoleByGroupUuidAndUserUuid: (groupUuid, userUuid, roleUuid) =>
    @auth.call "#{@namespace}.addRoleByGroupUuidAndUserUuid", {
      userUuid, groupUuid, roleUuid
    }, {invalidateAll: true}

  removeRoleByGroupUuidAndUserUuid: (groupUuid, userUuid, roleUuid) =>
    @auth.call "#{@namespace}.removeRoleByGroupUuidAndUserUuid", {
      userUuid, groupUuid, roleUuid
    }, {invalidateAll: true}

  addXpByGroupUuidAndUserUuid: (groupUuid, userUuid, xp) =>
    @auth.call "#{@namespace}.addXpByGroupUuidAndUserUuid", {
      userUuid, groupUuid, xp
    }, {invalidateAll: true}

  getByGroupUuidAndUserUuid: (groupUuid, userUuid) =>
    @auth.stream "#{@namespace}.getByGroupUuidAndUserUuid", {groupUuid, userUuid}

  getTopByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getTopByGroupUuid", {groupUuid}

  getMeSettingsByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getMeSettingsByGroupUuid", {groupUuid}

  getOnlineCountByGroupUuid: (groupUuid) =>
    @auth.stream "#{@namespace}.getOnlineCountByGroupUuid", {groupUuid}

  updateMeSettingsByGroupUuid: (groupUuid, {globalNotifications}) =>
    @auth.call "#{@namespace}.updateMeSettingsByGroupUuid", {
      groupUuid, globalNotifications
    }

  hasPermission: ({meGroupUser, me, permissions, channelUuid, roles}) ->
    roles ?= meGroupUser?.roles
    isGlobalModerator = me?.flags?.isModerator
    isGlobalModerator or _every permissions, (permission) ->
      _find roles, (role) ->
        channelPermissions = channelUuid and role.channelPermissions?[channelUuid]
        globalPermissions = role.globalPermissions
        permissions = _defaults(
          channelPermissions, globalPermissions, config.DEFAULT_PERMISSIONS
        )
        permissions[permission]
