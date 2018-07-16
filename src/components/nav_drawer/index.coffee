z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_take = require 'lodash/take'
_isEmpty = require 'lodash/isEmpty'
_orderBy = require 'lodash/orderBy'
_clone = require 'lodash/clone'
_find = require 'lodash/find'
Environment = require '../../services/environment'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/map'

Icon = require '../icon'
FlatButton = require '../flat_button'
AdsenseAd = require '../adsense_ad'
ClanBadge = require '../clan_badge'
GroupBadge = require '../group_badge'
Drawer = require '../drawer'
SemverService = require '../../services/semver'
Ripple = require '../ripple'
colors = require '../../colors'
config = require '../../config'

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap.js'
  require './index.styl'

module.exports = class NavDrawer
  constructor: ({@model, @router, group, @overlay$}) ->
    @$adsenseAd = new AdsenseAd {@model, group}
    @$groupBadge = new GroupBadge {@model, group}
    @$socialIcon = new Icon()
    @$drawer = new Drawer {
      @model
      isOpen: @model.drawer.isOpen()
      onOpen: @model.drawer.open
      onClose: @model.drawer.close
    }

    me = @model.user.getMe()
    groupPages = group.switchMap (group) =>
      @model.groupPage.getAllByGroupId group.id
    menuItemsInfo = RxObservable.combineLatest(
      me
      group
      groupPages
      @model.l.getLanguage()
      (vals...) -> vals
    )

    myGroups = me.switchMap (me) =>
      @model.group.getAllByUserId me.id
    groupAndMyGroups = RxObservable.combineLatest(
      group
      myGroups
      me
      @model.l.getLanguage()
      (vals...) -> vals
    )

    @state = z.state
      isOpen: @model.drawer.isOpen()
      language: @model.l.getLanguage()
      me: me
      expandedItems: []
      group: group
      myGroups: groupAndMyGroups.map (props) =>
        [group, groups, me, language] = props
        groups = _orderBy groups, (group) =>
          @model.cookie.get("group_#{group.id}_lastVisit") or 0
        , 'desc'
        groups = _filter groups, ({id}) ->
          id isnt group.id
        myGroups = _map groups, (group, i) =>
          {
            group
            key: group.key
            $badge: if group.clan \
                    then new ClanBadge {@model, clan: group.clan}
                    else new GroupBadge {@model, group}
          }
        myGroups

      windowSize: @model.window.getSize()
      drawerWidth: @model.window.getDrawerWidth()
      breakpoint: @model.window.getBreakpoint()

      menuItems: menuItemsInfo.map ([me, group, groupPages, language]) =>
        meGroupUser = group.meGroupUser

        userAgent = navigator?.userAgent
        hasGroupApp = group.googlePlayAppId
        needsGroupApp = hasGroupApp and
                          not Environment.isGroupApp group.key, {userAgent}
        needsMainApp = userAgent and
                  not Environment.isNativeApp('freeroam', {userAgent}) and
                  not window?.matchMedia('(display-mode: standalone)').matches

        _filter([
          {
            path: @model.group.getPath group, 'groupHome', {@router}
            title: @model.l.get 'general.home'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'home'
            isDefault: true
          }
          {
            path: @model.group.getPath group, 'groupChat', {@router}
            title: @model.l.get 'general.chat'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'chat'
          }
          {
            path: @router.get 'conversations'
            title: @model.l.get 'drawer.menuItemPrivateMessages'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'chat-bubble'
          }
          {
            path: @model.group.getPath group, 'groupForum', {@router}
            title: @model.l.get 'general.forum'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'rss'
          }
          # {
          #   path: @model.group.getPath group, 'groupPeople', {@router}
          #   title: @model.l.get 'people.title'
          #   $icon: new Icon()
          #   $ripple: new Ripple()
          #   iconName: 'friends'
          # }
          {
            path: @model.group.getPath group, 'groupProfile', {@router}
            title: @model.l.get 'drawer.menuItemProfile'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'profile'
          }
          # if @model.groupUser.hasPermission {
          #   meGroupUser, me, permissions: ['manageRole']
          # }
          #   {
          #     # path: @model.group.getPath group, 'groupSettings', {@router}
          #     expandOnClick: true
          #     title: @model.l.get 'groupSettingsPage.title'
          #     $icon: new Icon()
          #     $ripple: new Ripple()
          #     iconName: 'settings'
          #     $chevronIcon: new Icon()
          #     children: _filter [
          #       {
          #         path: @model.group.getPath group, 'groupManageChannels', {
          #           @router
          #         }
          #         title: @model.l.get 'groupManageChannelsPage.title'
          #       }
          #       {
          #         path: @model.group.getPath group, 'groupManagePages', {
          #           @router
          #         }
          #         title: @model.l.get 'groupManagePagesPage.title'
          #       }
          #       {
          #         path: @model.group.getPath group, 'groupManageRoles', {
          #           @router
          #         }
          #         title: @model.l.get 'groupManageRolesPage.title'
          #       }
          #       if @model.groupUser.hasPermission {
          #         meGroupUser, me, permissions: ['readAuditLog']
          #       }
          #         {
          #           path: @model.group.getPath group, 'groupAuditLog', {
          #             @router
          #           }
          #           title: @model.l.get 'groupAuditLogPage.title'
          #         }
          #       {
          #         path: @model.group.getPath group, 'groupBannedUsers', {
          #           @router
          #         }
          #         title: @model.l.get 'groupBannedUsersPage.title'
          #       }
          #       if me?.username in ['austin', 'brunoph']
          #         {
          #           path: @model.group.getPath group, 'groupSendNotification', {
          #             @router
          #           }
          #           title: @model.l.get 'groupSendNotificationPage.title'
          #         }
          #     ]
          #   }
          if needsMainApp or needsGroupApp
            {
              isDivider: true
            }
          if needsMainApp or needsGroupApp
            {
              onclick: =>
                @model.portal.call 'app.install', {group}
              title: @model.l.get 'drawer.menuItemNeedsApp'
              $icon: new Icon()
              $ripple: new Ripple()
              iconName: 'get'
            }
          ])

  isExpandedByPath: (path) =>
    {expandedItems} = @state.getValue()
    expandedItems.indexOf(path) isnt -1

  toggleExpandItemByPath: (path) =>
    {expandedItems} = @state.getValue()
    isExpanded = @isExpandedByPath path

    if isExpanded
      expandedItems = _clone expandedItems
      expandedItems.splice expandedItems.indexOf(path), 1
      @state.set expandedItems: expandedItems
    else
      @state.set expandedItems: expandedItems.concat [path]

  render: ({currentPath}) =>
    {isOpen, me, menuItems, myGroups, drawerWidth, breakpoint, group,
      language, windowSize, groupPages} = @state.getValue()

    group ?= {}

    translateX = if isOpen then 0 else "-#{drawerWidth}px"
    # adblock plus blocks has-ad
    hasA = @model.ad.isVisible({isWebOnly: true}) and
      windowSize?.height > 880 and
      not Environment.isMobile()

    isGroupApp = group.key and Environment.isGroupApp group.key

    renderChild = (child, depth = 0) =>
      {path, title, $chevronIcon, children, expandOnClick} = child
      isSelected = currentPath?.indexOf(path) is 0
      isExpanded = isSelected or @isExpandedByPath(path or title)

      hasChildren = not _isEmpty children
      z 'li.menu-item',
        z 'a.menu-item-link.is-child', {
          className: z.classKebab {isSelected}
          href: path
          onclick: (e) =>
            e.preventDefault()
            if expandOnClick
              expand()
            else
              @model.drawer.close()
              @router.goPath path
        },
          z '.icon'
          title
          if hasChildren
            z '.chevron',
              z $chevronIcon,
                icon: if isExpanded \
                      then 'chevron-up'
                      else 'chevron-down'
                color: colors.$tertiary500Text70
                isAlignedRight: true
                onclick: expand
        if hasChildren and isExpanded
          z "ul.children-#{depth}",
            _map children, (child) ->
              renderChild child, depth + 1

    z '.z-nav-drawer',
      z @$drawer,
        $content:
          z '.z-nav-drawer_drawer', {
            className: z.classKebab {hasA}
          },
            z '.header',
              z '.icon',
                z @$groupBadge
              z '.name',
                @model.group.getDisplayName group
            z '.content',
              z 'ul.menu',
                [
                  if me and not me?.isMember
                    [
                      z 'li.sign-in-buttons',
                        z '.button', {
                          onclick: =>
                            @model.signInDialog.open 'signIn'
                        }, @model.l.get 'general.signIn'
                        z '.button', {
                          onclick: =>
                            @model.signInDialog.open()
                        }, @model.l.get 'general.signUp'
                      z 'li.divider'
                    ]
                  _map menuItems, (menuItem) =>
                    {path, onclick, title, $icon, $chevronIcon, $ripple, isNew,
                      iconName, isDivider, children, expandOnClick} = menuItem

                    hasChildren = not _isEmpty children

                    if isDivider
                      return z 'li.divider'

                    if menuItem.isDefault
                      isSelected = currentPath in [
                        @router.get 'siteHome'
                        @model.group.getPath group, 'groupHome', {@router}
                        '/'
                      ]
                    else
                      isSelected = currentPath?.indexOf(path) is 0

                    isExpanded = isSelected or @isExpandedByPath(path or title)

                    expand = (e) =>
                      e?.stopPropagation()
                      e?.preventDefault()
                      @toggleExpandItemByPath path or title

                    z 'li.menu-item', {
                      className: z.classKebab {isSelected}
                    },
                      z 'a.menu-item-link', {
                        href: path
                        onclick: (e) =>
                          e.preventDefault()
                          if expandOnClick
                            expand()
                          else if onclick
                            onclick()
                            @model.drawer.close()
                          else if path
                            @router.goPath path
                            @model.drawer.close()
                      },
                        z '.icon',
                          z $icon,
                            isTouchTarget: false
                            icon: iconName
                            color: colors.$primary500
                        title
                        if isNew
                          z '.new', @model.l.get 'general.new'
                        if hasChildren
                          z '.chevron',
                            z $chevronIcon,
                              icon: if isExpanded \
                                    then 'chevron-up'
                                    else 'chevron-down'
                              color: colors.$tertiary500Text70
                              isAlignedRight: true
                              touchHeight: '28px'
                              onclick: expand
                        if breakpoint is 'desktop'
                          z $ripple
                      if hasChildren and isExpanded
                        z 'ul.children',
                          _map children, (child) ->
                            renderChild child, 1

                  unless _isEmpty myGroups
                    z 'li.divider'

                  # z 'li.subhead', @model.l.get 'drawer.otherGroups'
              ]

              unless isGroupApp
                z '.my-groups',
                  z '.my-groups-scroller', {
                    ontouchstart: (e) ->
                      # don't close drawer w/ iscroll
                      e?.stopPropagation()
                  },
                    [
                      _map myGroups, (myGroup) =>
                        {$badge} = myGroup
                        groupPath = @model.group.getPath(
                          myGroup.group, 'groupHome', {@router}
                        )
                        z 'a.group-bubble', {
                          href: groupPath
                          onclick: (e) =>
                            e.preventDefault()
                            @model.drawer.close()
                            @router.goPath groupPath
                        },
                          z $badge, {isRound: true}

                      z '.a.group-bubble', {
                        href: @router.get 'groups'
                        onclick: (e) =>
                          e.preventDefault()
                          @model.drawer.close()
                          @router.go 'groups'
                      },
                        z '.icon',
                          z @$socialIcon,
                            icon: 'add'
                            isTouchTarget: false
                            color: colors.$primary500
                    ]

            if hasA
              z '.ad',
                z @$adsenseAd, {
                  slot: 'desktop336x280'
                }
