z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
Fab = require '../fab'
GroupRolePermissions = require '../group_role_permissions'
Dialog = require '../dialog'
PrimaryInput = require '../primary_input'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageRoles
  constructor: ({@model, @router, group}) ->

    @$fab = new Fab()
    @$addIcon = new Icon()


    groupAndMe = RxObservable.combineLatest(
      group
      @model.user.getMe()
      (vals...) -> vals
    )
    permissionTypes = groupAndMe.map ([group, me]) =>
      permissions = [
        'manageInfo'
        'readAuditLog'
        'manageChannel'
        'managePage'
        'manageRole'
        'permaBanUser'
        'tempBanUser'
        'unbanUser'
        'deleteMessage'
        'sendMessage'
        'sendLink'
        'sendImage'
        'mentionEveryone'
        'deleteForumThread'
        'pinForumThread'
        'deleteForumComment'
      ]
      if @model.groupUser.hasPermission {
        meGroupUser: group.meGroupUser, me, permissions: ['admin']
      }
        permissions.unshift 'admin'
      permissions

    @$groupRolePermissions = new GroupRolePermissions {
      @model, @router, group, permissionTypes, onSave: @save
    }
    @$newRoleDialog = new Dialog {
    onLeave: =>
      @state.set isNewRoleDialogVisible: false
    }
    @newRoleNameValue = new RxBehaviorSubject ''
    @$newRoleInput = new PrimaryInput {value: @newRoleNameValue}

    @state = z.state {
      group
      isNewRoleDialogVisible: false
      me: @model.user.getMe()
    }

  save: (roleId, permissions) =>
    {group, conversation} = @state.getValue()

    @model.groupRole.updatePermissions(
      {roleId, isGlobal: true, groupId: group.id, permissions}
    )

  addRole: =>
    {group} = @state.getValue()
    name = @newRoleNameValue.getValue()
    @model.groupRole.createByGroupId group.id, {name}

  render: =>
    {me, group, roles, isNewRoleDialogVisible} = @state.getValue()

    z '.z-group-manage-roles',
      @$groupRolePermissions

      z '.fab',
        z @$fab,
          colors:
            c500: colors.$primary500
          $icon: z @$addIcon, {
            icon: 'add'
            isTouchTarget: false
            color: colors.$primary500Text
          }
          onclick: =>
            @state.set isNewRoleDialogVisible: true

      if isNewRoleDialogVisible
        z @$newRoleDialog,
          isVanilla: true
          $title: @model.l.get 'groupManageRoles.addRole'
          $content:
            z '.z-group-manage-roles_new-role-dialog',
              z @$newRoleInput,
                hintText: @model.l.get 'general.name'
          cancelButton:
            text: @model.l.get 'general.cancel'
            onclick: =>
              @state.set isNewRoleDialogVisible: false
          submitButton:
            text: @model.l.get 'general.done'
            onclick: =>
              @addRole()
              .then =>
                @state.set isNewRoleDialogVisible: false
