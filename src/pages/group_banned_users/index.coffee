z = require 'zorium'
isUuid = require 'isuuid'
_filter = require 'lodash/filter'
Environment = require '../../services/environment'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/map'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Tabs = require '../../components/tabs'
GroupBannedUsers = require '../../components/group_banned_users'
ProfileDialog = require '../../components/profile_dialog'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupBannedUsersPage
  isGroup: true
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}

    @selectedProfileDialogUser = new RxBehaviorSubject null
    @$profileDialog = new ProfileDialog {
      @model, @portal, @router, @selectedProfileDialogUser, group
    }

    @$tempBanned = new GroupBannedUsers {
      @model
      selectedProfileDialogUser: @selectedProfileDialogUser
      bans: group.switchMap (group) =>
        @model.ban.getAllByGroupId group.id, {duration: '24h'}
    }

    @$permBanned = new GroupBannedUsers {
      @model
      selectedProfileDialogUser: @selectedProfileDialogUser
      bans: group.switchMap (group) =>
        @model.ban.getAllByGroupId group.id, {duration: 'permanent'}
    }
    @$tabs = new Tabs {@model}

    @state = z.state
      group: group
      selectedProfileDialogUser: @selectedProfileDialogUser

  getMeta: =>
    {
      title: @model.l.get 'groupBannedUsersPage.title'
    }

  render: =>
    {group, selectedProfileDialogUser} = @state.getValue()

    z '.p-group-banned-users',
      z @$appBar, {
        title: @model.l.get 'groupBannedUsersPage.title'
        style: 'primary'
        isFlat: true
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'groupBannedUsersPage.tempBanned'
            $el: @$tempBanned
          }
          {
            $menuText: @model.l.get 'groupBannedUsersPage.permBanned'
            $el: z @$permBanned
          }
        ]
      if selectedProfileDialogUser
        @$profileDialog
