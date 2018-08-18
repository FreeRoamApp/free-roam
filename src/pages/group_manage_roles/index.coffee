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

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'groupManageRolesPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-manage-roles', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'groupManageRolesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$groupManageRoles
