z = require 'zorium'

GroupRolePermissions = require '../group_role_permissions'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupEditChannelPermissions
  constructor: ({@model, @router, group, conversation}) ->
    me = @model.user.getMe()

    permissionTypes = [
      'readMessage'
      'sendMessage'
      'sendLink'
      'sendImage'
    ]

    @$groupRolePermissions = new GroupRolePermissions {
      @model, @router, group, permissionTypes
      conversation, onSave: @save
    }

    @state = z.state
      me: me
      group: group
      conversation: conversation

  save: (roleId, permissions) =>
    {group, conversation} = @state.getValue()

    console.log 'save', conversation

    @model.groupRole.updatePermissions(
      {roleId, channelId: conversation.id, groupId: group.id, permissions}
    )

  render: =>
    {me} = @state.getValue()

    console.log 'edit perm'

    z '.z-group-edit-channel-permissions',
      @$groupRolePermissions
