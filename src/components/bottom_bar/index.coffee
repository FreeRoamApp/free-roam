z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class BottomBar
  constructor: ({@model, @router, requests, group, @serverData}) ->
    # don't need to slow down server-side rendering for this
    hasUnreadMessages = if window?
      @model.conversation.getAll().map (conversations) ->
        hasWelcomeMessage = _isEmpty conversations
        hasWelcomeMessage or _some conversations, {isRead: false}
    else
      RxObservable.of null

    @state = z.state
      me: @model.user.getMe()
      hasUnreadMessages: hasUnreadMessages
      requests: requests
      group: group
      currentPath: requests.map ({req}) ->
        req.path
      serverData: @serverData

  afterMount: (@$$el) => null

  hide: =>
    @$$el?.classList.add 'is-hidden'

  show: =>
    @$$el?.classList.remove 'is-hidden'

  render: ({isAbsolute} = {}) =>
    {me, hasUnreadMessages, requests, group,
      currentPath, serverData} = @state.getValue()

    userAgent = @model.window.getUserAgent()
    isLoaded = true # Boolean group

    @menuItems = _filter [
      {
        $icon: new Icon()
        icon: 'map'
        route: @router.get 'places'
        text: @model.l.get 'general.places'
        isDefault: true
      }
      {
        $icon: new Icon()
        icon: 'guides'
        route: @router.get 'guides'
        text: @model.l.get 'guidesPage.title'
      }
      {
        $icon: new Icon()
        icon: 'home'
        route: @router.get 'dashboard'
        text: @model.l.get 'general.dashboard'
      }
      {
        $icon: new Icon()
        icon: 'profile'
        route: @router.get 'profileMe'
        text: @model.l.get 'general.profile'
      }
      {
        $icon: new Icon()
        icon: 'chat-bubble'
        route: @router.get 'social'
        text: @model.l.get 'general.social'
        hasNotification: hasUnreadMessages
      }
    ]

    z '.z-bottom-bar', {
      key: 'bottom-bar'
      className: z.classKebab {isLoaded, isAbsolute}
    },
      _map @menuItems, (menuItem, i) =>
        {$icon, icon, route, text, isDefault, hasNotification} = menuItem

        if isDefault
          isSelected = currentPath is @router.get('home') or
            (currentPath and currentPath.indexOf(route) isnt -1)
        else
          isSelected = currentPath and currentPath.indexOf(route) isnt -1

        z 'a.menu-item', {
          attributes:
            tabindex: i
          className: z.classKebab {isSelected, hasNotification}
          href: route
          onclick: (e) =>
            e?.preventDefault()
            # without delay, browser will wait until the next render is complete
            # before showing ripple. seems better to start ripple animation
            # first
            setTimeout =>
              @router.goPath route
            , 0
          # ontouchstart: (e) =>
          #   e?.stopPropagation()
          #   @router.goPath route
          # onclick: (e) =>
          #   e?.stopPropagation()
          #   @router.goPath route
        },
          z '.icon',
            z $icon,
              icon: icon
              color: if isSelected then colors.$primary500 else colors.$bgText54
              isTouchTarget: false
          z '.text', text
