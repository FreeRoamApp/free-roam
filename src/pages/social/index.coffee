z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Conversations = require '../../components/conversations'
Friends = require '../../components/friends'
Groups = require '../../components/groups'
UsersNearby = require '../../components/users_nearby'
Icon = require '../../components/icon'
Tabs = require '../../components/tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SocialPage
  @hasBottomBar: true

  constructor: ({@model, @router, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$chatIcon = new Icon()
    @$usersNearbyIcon = new Icon()
    @$pmsIcon = new Icon()
    @$friendsIcon = new Icon()

    @$conversations = new Conversations {@model, @router}
    @$friends = new Friends {@model, @router}
    @$groups = new Groups {@model, @router}
    @$usersNearby = new UsersNearby {@model, @router}

    # don't need to slow down server-side rendering for this
    hasUnreadMessages = if window?
      @model.conversation.getAll().map (conversations) ->
        hasWelcomeMessage = _isEmpty conversations
        hasWelcomeMessage or _some conversations, {isRead: false}
    else
      RxObservable.of null

    @state = z.state {
      hasUnreadMessages
    }


  getMeta: =>
    {
      title: @model.l.get 'socialPage.title'
    }

  render: =>
    {hasUnreadMessages} = @state.getValue()

    z '.p-social',
      z @$appBar, {
        title: @model.l.get 'socialPage.title'
        isFlat: true
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
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
