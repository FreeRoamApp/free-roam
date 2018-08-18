z = require 'zorium'
isUuid = require 'isuuid'

GroupManageMember = require '../../components/group_manage_member'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageMemberPage
  hideDrawer: true
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    user = requests.switchMap ({route}) =>
      @model.user.getById route.params.userId

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$groupManageMember = new GroupManageMember {
      @model, @router, serverData, group, user
    }

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'groupManageMemberPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-manage-member', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'groupManageMemberPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$groupManageMember
