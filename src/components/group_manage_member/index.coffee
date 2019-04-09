z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switchMap'
_map = require 'lodash/map'
_filter = require 'lodash/filter'

Dropdown = require '../dropdown'
PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
DateService = require '../../services/date'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageMember
  constructor: ({@model, @router, group, user}) ->
    groupAndMe = RxObservable.combineLatest(
      group
      @model.user.getMe()
      (vals...) -> vals
    )

    roles = groupAndMe.switchMap ([group, me]) =>
      @model.groupRole.getAllByGroupId group.id
      .map (roles) =>
        meHasAdminPermission = @model.groupUser.hasPermission {
          meGroupUser: group.meGroupUser, me, permissions: ['admin']
        }
        _filter roles, (role) =>
          roleHasAdminPermission = @model.groupUser.hasPermission {
            roles: [role], permissions: ['admin']
          }
          not roleHasAdminPermission or meHasAdminPermission

    @roleValueStreams = new RxReplaySubject 1
    @roleValueStreams.next roles.map (roles) ->
      roles?[0]?.roleId

    @$roleDropdown = new Dropdown {valueStreams: @roleValueStreams}
    @$addRoleButton = new PrimaryButton()


    groupAndUser = RxObservable.combineLatest(group, user, (vals...) -> vals)

    @state = z.state
      groupUser: groupAndUser.switchMap ([group, user]) =>
        @model.groupUser.getByGroupIdAndUserId group.id, user.id
      roleId: @roleValueStreams.switch()
      group: group
      user: user
      roles: roles
      me: @model.user.getMe()
      windowSize: @model.window.getSize()
      appBarHeight: @model.window.getAppBarHeight()

  addRole: =>
    {group, user, roleId} = @state.getValue()
    @model.groupUser.addRoleByGroupIdAndUserId group.id, user.id, roleId

  render: =>
    {groupUser, group, user, me, windowSize,
      appBarHeight, roles, roleId} = @state.getValue()

    z '.z-group-manage-member', {
      style:
        height: "#{windowSize.height - appBarHeight}px"
    },
      z '.content', {
        style:
          height: "#{windowSize.height - appBarHeight}px"
      },
        z '.info',
          z '.g-grid',
            z '.flex',
              z '.name', @model.user.getDisplayName user
        z '.g-grid',
          z '.row',
            z '.roles',
              _map groupUser?.roles, (role) =>
                z '.role', {
                  onclick: =>
                    @model.groupUser.removeRoleByGroupIdAndUserId(
                      group.id, user.id, role.id
                    )
                }, role.name
          z '.row',
            z @$roleDropdown,
              hintText: 'Type'
              isFloating: false
              options: _map roles, (role) ->
                {value: role.id, text: role.name}
            z '.button',
              z @$addRoleButton,
                text: @model.l.get 'groupManageMember.addRole'
                onclick: @addRole
