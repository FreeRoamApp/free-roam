z = require 'zorium'
isUuid = require 'isuuid'

GroupManageRoles = require '../../components/group_manage_roles'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageRolesPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    user = requests.switchMap ({route}) =>
      @model.user.getById route.params.userId

    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupManageRoles = new GroupManageRoles {
      @model, @router, serverData, group, user
    }

  getMeta: =>
    {
      title: @model.l.get 'groupManageRolesPage.title'
    }

  render: =>
    z '.p-group-manage-roles',
      z @$appBar, {
        title: @model.l.get 'groupManageRolesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$groupManageRoles
