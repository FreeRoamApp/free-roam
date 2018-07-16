z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

collectionGroupKeys = [
  'playhard', 'eclihpse', 'nickatnyte', 'ferg'
  'teamqueso', 'ninja', 'theviewage'
]

module.exports = class BottomBar
  constructor: ({@model, @router, requests, group}) ->
    @state = z.state
      requests: requests
      group: group
      hasShopNotification: group.switchMap (group) =>
        if group and group.key in collectionGroupKeys
          @model.product.getAllByGroupId group.id
        else
          RxObservable.of null
      .map (products) ->
        Boolean _find products, ({cost, isLocked}) ->
          cost is 0 and not isLocked

  afterMount: (@$$el) => null

  hide: =>
    @$$el?.classList.add 'is-hidden'

  show: =>
    @$$el?.classList.remove 'is-hidden'

  render: ({isAbsolute} = {}) =>
    {requests, group, hasShopNotification} = @state.getValue()

    currentPath = requests?.req.path

    isLoaded = Boolean group

    # per-group menu:
    # profile, tools, home, forum, chat
    @menuItems = _filter [
      if group?.key in ['nickatnyte', 'theviewage']
        {
          $icon: new Icon()
          icon: 'trade'
          route: @model.group.getPath group, 'trades', {@router}
          text: @model.l.get 'tradesPage.title'
        }
      else if @model.group.hasGameKey group, 'fortnite'
        {
          $icon: new Icon()
          icon: 'friends'
          route: @model.group.getPath group, 'groupPeople', {@router}
          text: @model.l.get 'people.title'
        }
      else
        {
          $icon: new Icon()
          icon: 'profile'
          route: @model.group.getPath group, 'groupProfile', {@router}
          text: @model.l.get 'general.profile'
        }
      {
        $icon: new Icon()
        icon: 'chat'
        route: @model.group.getPath group, 'groupChat', {@router}
        text: @model.l.get 'general.chat'
      }
      {
        $icon: new Icon()
        icon: 'home'
        route: @model.group.getPath group, 'groupHome', {@router}
        text: @model.l.get 'general.home'
        isDefault: true
      }
      if group?.key in collectionGroupKeys
        {
          $icon: new Icon()
          icon: 'cards'
          route: if hasShopNotification
            @model.group.getPath group, 'groupCollectionWithTab', {
              @router, replacements: {tab: 'shop'}
            }
          else
            @model.group.getPath group, 'groupCollection', {@router}
          text: @model.l.get 'general.collection'
          hasNotification: hasShopNotification
        }
      else if group?.type is 'public'
        {
          $icon: new Icon()
          icon: 'rss'
          route: @model.group.getPath group, 'groupForum', {@router}
          text: @model.l.get 'general.forum'
        }
      {
        $icon: new Icon()
        icon: 'tools'
        route: @model.group.getPath group, 'groupTools', {@router}
        text: @model.l.get 'general.tools'
      }
    ]

    z '.z-bottom-bar', {
      key: 'bottom-bar'
      className: z.classKebab {isLoaded, isAbsolute}
    },
      _map @menuItems, (menuItem, i) =>
        {$icon, icon, route, text, isDefault, hasNotification} = menuItem

        if isDefault
          isSelected =  currentPath in [
            @router.get 'siteHome'
            @model.group.getPath group, 'groupHome', {@router}
            '/'
          ]
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
            setImmediate =>
              @router.goPath route
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
              color: if isSelected then colors.$primary500 else colors.$tertiary900Text54
              isTouchTarget: false
          z '.text', text
