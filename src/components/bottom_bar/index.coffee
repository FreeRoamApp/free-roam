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

  afterMount: (@$$el) => null

  hide: =>
    @$$el?.classList.add 'is-hidden'

  show: =>
    @$$el?.classList.remove 'is-hidden'

  render: ({isAbsolute} = {}) =>
    {requests, group} = @state.getValue()

    currentPath = requests?.req.path

    isLoaded = Boolean group

    # per-group menu:
    # profile, tools, home, forum, chat
    @menuItems = _filter [
      {
        $icon: new Icon()
        icon: 'profile'
        route: ''
        text: @model.l.get 'general.profile'
      }
      {
        $icon: new Icon()
        icon: 'chat'
        route: ''
        text: @model.l.get 'general.chat'
      }
      {
        $icon: new Icon()
        icon: 'home'
        route: ''
        text: @model.l.get 'general.home'
        isDefault: true
      }
      {
        $icon: new Icon()
        icon: 'rss'
        route: @model.group.getPath group, 'groupForum', {@router}
        text: @model.l.get 'general.forum'
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
            ''
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
