z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_reduce = require 'lodash/reduce'
_find = require 'lodash/find'
_isEmpty = require 'lodash/isEmpty'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switch'

FlatButton = require '../flat_button'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
Spinner = require '../spinner'
Dropdown = require '../dropdown'
Toggle = require '../toggle'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupRolePermissions
  constructor: (props) ->
    {@model, @router, group, conversation, permissionTypes, @onSave} = props
    me = @model.user.getMe()

    @roles = group.switchMap (group) =>
      @model.groupRole.getAllByGroupId group.id

    @roleValueStreams = new RxReplaySubject 1
    @roleValueStreams.next @roles.map (roles) ->
      roles?[0]?.id

    permissionTypesData = RxObservable.combineLatest(
      group
      @roles
      @roleValueStreams.switch()
      conversation or RxObservable.of null
      if permissionTypes.subscribe \
      then permissionTypes
      else RxObservable.of permissionTypes
      (vals...) -> vals
    )

    @$roleDropdown = new Dropdown {valueStreams: @roleValueStreams}
    @$cancelButton = new FlatButton()
    @$saveButton = new PrimaryButton()
    @$deleteRoleButton = new SecondaryButton()
    @$spinner = new Spinner()

    @state = z.state
      me: me
      isSaving: false
      group: group
      roles: @roles
      roleId: @roleValueStreams.switch()
      permissionTypes: permissionTypesData.map (response) =>
        [group, roles, roleId, conversation, permissionTypes] = response

        role = _find roles, {id: roleId}

        _map permissionTypes, (key) =>
          isSelected = new RxBehaviorSubject(
            @model.groupUser.hasPermission {
              channelId: conversation?.id
              roles: [role]
              permissions: [key]
            }
          )

          {
            $toggle: new Toggle {isSelected}
            isSelected: isSelected
            key: key
          }

  save: =>
    {me, isSaving, roleId, permissionTypes} = @state.getValue()

    if isSaving
      return

    @state.set isSaving: true

    permissions = _reduce permissionTypes, (obj, type) ->
      obj[type.key] = type.isSelected.getValue()
      obj
    , {}
    @onSave roleId, permissions
    .then =>
      @state.set isSaving: false

  deleteRole: =>
    {group, roleId, roles} = @state.getValue()
    if confirm 'Confirm?'
      @model.groupRole.deleteByGroupIdAndRoleId group.id, roleId
      @roleValueStreams.next RxObservable.of(
        _find(roles, {name: 'everyone'})?.id
      )

  render: =>
    {me, isSaving, group, roles, roleId, permissionTypes} = @state.getValue()

    role = _find roles, {id: roleId}

    z '.z-group-role-permissions',
      if _isEmpty roles
        @$spinner
      else
        z '.g-grid',
          z '.label',
            @model.l.get 'groupRolePermissions.selectRole'
            ': '
            z '.dropdown',
              z @$roleDropdown,
                hintText: 'Type'
                isFloating: false
                options: _map roles, (role) ->
                  {value: role.id, text: role.name}
          z 'ul.list',
            _map permissionTypes, ({key, $toggle, isSelected}) =>
              z 'li.item',
                z '.text', @model.l.get "permissions.#{key}"
                z '.toggle',
                  z $toggle

          if role?.name isnt 'everyone'
            z '.delete-button',
              z @$deleteRoleButton,
                text: @model.l.get 'groupRolePermissions.deleteRole'
                onclick: @deleteRole
                isFullWidth: false

          z '.actions',
            z '.cancel-button',
              z @$cancelButton,
                isFullWidth: false
                text: @model.l.get 'general.cancel'
                onclick: =>
                  @router.back()
            z '.save-button',
              z @$saveButton,
                isFullWidth: false
                text: if isSaving \
                      then @model.l.get 'general.loading'
                      else @model.l.get 'general.save'
                onclick: =>
                  @save()
