z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Conversations = require '../../components/conversations'
Fab = require '../../components/fab'
FindFriends = require '../../components/find_friends'
Friends = require '../../components/friends'
Groups = require '../../components/groups'
UsersNearby = require '../../components/users_nearby'
ProfileDialog = require '../../components/profile_dialog'
Icon = require '../../components/icon'
Tabs = require '../../components/tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SocialPage
  @hasBottomBar: true

  constructor: ({@model, @router, @$bottomBar}) ->
    selectedIndex = new RxBehaviorSubject 0

    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model, selectedIndex}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$notificationsIcon = new Icon()
    @$chatIcon = new Icon()
    @$usersNearbyIcon = new Icon()
    @$pmsIcon = new Icon()
    @$friendsIcon = new Icon()
    @$fabIcon = new Icon()
    @$fab = new Fab()

    @selectedProfileDialogUser = new RxBehaviorSubject null

    @$conversations = new Conversations {@model, @router}
    @$friends = new Friends {@model, @router, @selectedProfileDialogUser}
    @$groups = new Groups {@model, @router}
    @$usersNearby = new UsersNearby {
      @model, @router, @selectedProfileDialogUser
    }
    @$profileDialog = new ProfileDialog {
      @model, @router, @selectedProfileDialogUser
    }

    # don't need to slow down server-side rendering for this
    hasUnreadMessages = if window?
      @model.conversation.getAll().map (conversations) ->
        hasWelcomeMessage = _isEmpty conversations
        hasWelcomeMessage or _some conversations, {isRead: false}
    else
      RxObservable.of null

    @state = z.state {
      hasUnreadMessages
      @selectedProfileDialogUser
      selectedIndex
      unreadNotifications: @model.notification.getUnreadCount()
    }


  getMeta: =>
    {
      title: @model.l.get 'socialPage.title'
    }

  render: =>
    {hasUnreadMessages, selectedProfileDialogUser,
      selectedIndex, unreadNotifications} = @state.getValue()
    z '.p-social',
      z @$appBar, {
        title: @model.l.get 'socialPage.title'
        isFlat: true
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z @$notificationsIcon,
            icon: 'notifications'
            color: if unreadNotifications \
                   then colors.$primary500
                   else colors.$bgText54
            onclick: =>
              @router.go 'notifications'
      }
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuIcon: @$chatIcon
            menuIconName: 'chat-bubble'
            $menuText: @model.l.get 'general.chat'
            $el: @$groups
          }
          {
            $menuIcon: @$usersNearbyIcon
            menuIconName: 'users-nearby'
            $menuText: @model.l.get 'social.peopleNearby'
            $el: z @$usersNearby
          }
          {
            $menuIcon: @$pmsIcon
            menuIconName: 'pms'
            $menuText: @model.l.get 'drawer.privateMessages'
            $el: z @$conversations
            hasNotification: hasUnreadMessages
          }
          {
            $menuIcon: @$friendsIcon
            menuIconName: 'friends'
            $menuText: @model.l.get 'general.friends'
            $el: z @$friends
          }
        ]
      @$bottomBar

      if selectedProfileDialogUser
        z @$profileDialog, {user: selectedProfileDialogUser}

      if selectedIndex is 3
        z '.fab',
          z @$fab,
            colors:
              c500: colors.$primary500
            $icon: z @$fabIcon, {
              icon: 'search'
              isTouchTarget: false
              color: colors.$primary500Text
            }
            onclick: =>
              @model.overlay.open new FindFriends {
                @model, @portal
                @selectedProfileDialogUser
              }
