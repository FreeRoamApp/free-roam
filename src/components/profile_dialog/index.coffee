z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_clone = require 'lodash/clone'
_isEmpty = require 'lodash/isEmpty'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/switchMap'

Avatar = require '../avatar'
Dialog = require '../dialog'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProfileDialog
  constructor: (options) ->
    {@model, @router, @selectedProfileDialogUser, group} = options
    @$dialog = new Dialog {
      onLeave: =>
        @selectedProfileDialogUser.next null
    }
    @$avatar = new Avatar()

    @$profileIcon = new Icon()
    @$friendIcon = new Icon()
    @$messageIcon = new Icon()
    @$manageIcon = new Icon()
    @$flagIcon = new Icon()
    @$blockIcon = new Icon()
    @$banIcon = new Icon()
    @$tempBanIcon = new Icon()
    @$permaBanIcon = new Icon()
    @$ipBanIcon = new Icon()
    @$deleteIcon = new Icon()
    @$delete1Icon = new Icon()
    @$delete24hIcon = new Icon()
    @$delete7dIcon = new Icon()
    @$editIcon = new Icon()
    @$banChevronIcon = new Icon()
    @$deleteChevronIcon = new Icon()
    @$closeIcon = new Icon()
    @$copyIcon = new Icon()

    me = @model.user.getMe()

    groupAndMe = RxObservable.combineLatest(
      group or RxObservable.of null
      me
      (vals...) -> vals
    )

    groupAndUser = RxObservable.combineLatest(
      group or RxObservable.of null
      @selectedProfileDialogUser
      (vals...) -> vals
    )

    @state = z.state
      me: me
      $links: @selectedProfileDialogUser.map (user) ->
        _map user?.links, (link, type) ->
          {
            $icon: new Icon()
            type: type
            link: link
          }
      meGroupUser: groupAndMe.switchMap ([group, me]) =>
        if group and me
          @model.groupUser.getByGroupIdAndUserId group.id, me.id
        else
          RxObservable.of null
      user: @selectedProfileDialogUser
      isBanned: groupAndUser.switchMap ([group, user]) =>
        if group and user
          @model.ban.getByGroupIdAndUserId group.id, user.id
        else
          RxObservable.of null
      isFriends: @selectedProfileDialogUser.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friend'
          )
        else
          RxObservable.of false
      isFriendRequested: @selectedProfileDialogUser.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friendRequestSent'
          )
        else
          RxObservable.of false
      group: group
      loadingItems: []
      expandedItems: []
      blockedUserIds: [] # TODO: @model.userBlock.getAllIds()
      windowSize: @model.window.getSize()

  isLoadingByText: (text) =>
    {loadingItems} = @state.getValue()
    loadingItems.indexOf(text) isnt -1

  setLoadingByText: (text) =>
    {loadingItems} = @state.getValue()
    @state.set loadingItems: loadingItems.concat [text]

  unsetLoadingByText: (text) =>
    {loadingItems} = @state.getValue()
    loadingItems = _clone loadingItems
    loadingItems.splice loadingItems.indexOf(text), 1
    @state.set loadingItems: loadingItems

  getModOptions: =>
    {me, user, meGroupUser, group, isBanned} = @state.getValue()

    isMe = user?.id is me?.id

    hasDeleteMessagePermission = isMe or @model.groupUser.hasPermission {
      group, meGroupUser, me
      permissions: ['deleteMessage']
    }
    hasTempBanPermission = @model.groupUser.hasPermission {
      group, meGroupUser, me
      permissions: ['tempBanUser']
    }
    hasPermaBanPermission = @model.groupUser.hasPermission {
      group, meGroupUser, me
      permissions: ['permaBanUser']
    }
    hasManagePermission = @model.groupUser.hasPermission {
      group, meGroupUser, me
      permissions: ['manageRole']
    }

    modOptions = _filter [
      if hasTempBanPermission
        {
          icon: 'warning'
          $icon: @$banIcon
          $chevronIcon: @$banChevronIcon
          text: @model.l.get 'profileDialog.ban'
          isVisible: not isMe
          children: _filter [
            if hasTempBanPermission
              {
                icon: 'warning'
                $icon: @$tempBanIcon
                text:
                  if isBanned
                    @model.l.get 'profileDialog.unban'
                  else
                    @model.l.get 'profileDialog.tempBan'
                isVisible: not isMe
                onclick: =>
                  if isBanned
                    @model.ban.unbanByGroupIdAndUserId group?.id, user?.id
                  else
                    @model.ban.banByGroupIdAndUserId group?.id, user?.id, {
                      duration: '24h', groupId: group?.id
                    }
                  @selectedProfileDialogUser.next null
              }
            if hasPermaBanPermission
              {
                icon: 'perma-ban'
                $icon: @$permaBanIcon
                text:
                  if isBanned
                    @model.l.get 'profileDialog.unban'
                  else
                    @model.l.get 'profileDialog.permaBan'
                isVisible: not isMe
                onclick: =>
                  if isBanned
                    @model.ban.unbanByGroupIdAndUserId group?.id, user?.id
                  else
                    @model.ban.banByGroupIdAndUserId group?.id, user?.id, {
                      duration: 'permanent'
                    }
                  @selectedProfileDialogUser.next null
              }
            if hasPermaBanPermission
              {
                icon: 'ip-ban'
                $icon: @$ipBanIcon
                text:
                  if isBanned
                    @model.l.get 'profileDialog.unban'
                  else
                    @model.l.get 'profileDialog.ipBan'
                isVisible: not isMe
                onclick: =>
                  if isBanned
                    @model.ban.unbanByGroupIdAndUserId group?.id, user?.id
                  else
                    @model.ban.banByGroupIdAndUserId group?.id, user?.id, {
                      type: 'ip', duration: 'permanent'
                    }
                  @selectedProfileDialogUser.next null
              }
          ]
        }
      if hasDeleteMessagePermission and user?.onDeleteMessage
        {
          icon: 'edit'
          $icon: @$deleteIcon
          $chevronIcon: @$deleteChevronIcon
          text: @model.l.get 'profileDialog.edit'
          isVisible: true
          children: _filter [
            {
              icon: 'edit'
              $icon: @$editIcon
              text: if @isLoadingByText @model.l.get 'profileDialog.edit' \
                    then @model.l.get 'general.loading'
                    else @model.l.get 'profileDialog.edit'
              isVisible: true
              onclick: ->
                user.onEditMessage()
            }
            {
              icon: 'delete'
              $icon: @$delete1Icon
              text: if @isLoadingByText @model.l.get 'profileDialog.delete' \
                    then @model.l.get 'general.loading'
                    else @model.l.get 'profileDialog.delete'
              isVisible: true
              onclick: =>
                unless confirm @model.l.get 'general.confirm'
                  return
                @setLoadingByText @model.l.get 'profileDialog.delete'
                user.onDeleteMessage()
                .then =>
                  @unsetLoadingByText @model.l.get 'profileDialog.delete'
                  @selectedProfileDialogUser.next null
            }
            if group
              {
                icon: 'delete'
                $icon: @$delete7dIcon
                text: if @isLoadingByText @model.l.get 'profileDialog.deleteMessagesLast7d' \
                      then @model.l.get 'general.loading'
                      else @model.l.get 'profileDialog.deleteMessagesLast7d'
                isVisible: true
                onclick: =>
                  @setLoadingByText(
                    @model.l.get 'profileDialog.deleteMessagesLast7d'
                  )
                  user.onDeleteMessagesLast7d()
                  .then =>
                    @unsetLoadingByText(
                      @model.l.get 'profileDialog.deleteMessagesLast7d'
                    )
                    @selectedProfileDialogUser.next null
              }
          ]
        }
      if hasManagePermission and group
        {
          icon: 'settings'
          $icon: @$manageIcon
          text: @model.l.get 'general.manage'
          isVisible: true
          onclick: =>
            @model.group.goPath group, 'groupAdminManage', {
              @router, replacements: {userId: user?.id}
            }
            @selectedProfileDialogUser.next null
        }
    ]

  getUserOptions: =>
    {me, user, blockedUserIds, isFlagged,
      isFriends, isFriendRequested, group} = @state.getValue()

    isBlocked = @model.userBlock.isBlocked blockedUserIds, user?.id

    isMe = user?.id is me?.id

    _filter [
      {
        icon: 'profile'
        $icon: @$profileIcon
        text: @model.l.get 'general.profile'
        # isVisible: not isMe
        onclick: =>
          if user?.username
            @router.go 'profile', {username: user?.username}
          else
            @router.go 'profileById', {id: user?.id}
          @selectedProfileDialogUser.next null
      }
      {
        icon: 'chat-bubble'
        $icon: @$messageIcon
        text:
          if @isLoadingByText @model.l.get 'profileDialog.message'
          then @model.l.get 'general.loading'
          else @model.l.get 'profileDialog.message'
        isVisible: not isMe
        onclick: =>
          unless @isLoadingByText @model.l.get 'profileDialog.message'
            @setLoadingByText @model.l.get 'profileDialog.message'
            @model.conversation.create {
              userIds: [user.id]
            }
            .then (conversation) =>
              @unsetLoadingByText @model.l.get 'profileDialog.message'
              @router.go 'conversation', {id: conversation.id}
              @selectedProfileDialogUser.next null
      }
      {
        icon: 'add-friend'
        $icon: @$friendIcon
        text:
          if isFriends
          then @model.l.get 'profile.unfriend'
          else if isFriendRequested
          then @model.l.get 'profile.sentFriendRequest'
          else if @isLoadingByText @model.l.get 'profile.addFriend'
          then @model.l.get 'general.loading'
          else @model.l.get 'profile.addFriend'
        isVisible: not isMe
        onclick: =>
          isLoading = @isLoadingByText @model.l.get 'profile.addFriend'
          if not isLoading
            @model.user.requestLoginIfGuest me
            .then =>
              if isFriends
                isConfirmed = confirm @model.l.get 'profile.confirmUnfriend'
                fn = =>
                  @model.connection.deleteByUserIdAndType(
                    user.id, 'friend'
                  )
              else
                isConfirmed = true
                fn = =>
                  @model.connection.upsertByUserIdAndType(
                    user.id, 'friendRequestSent'
                  )
              if isConfirmed and not isFriendRequested
                @setLoadingByText @model.l.get 'profile.addFriend'
                fn()
                .then =>
                  @unsetLoadingByText @model.l.get 'profile.addFriend'
      }
      unless user?.flags?.isModerator
        {
          icon: 'block'
          $icon: @$blockIcon
          text:
            if isBlocked
            then @model.l.get 'profileDialog.unblock'
            else @model.l.get 'profileDialog.block'
          isVisible: not isMe
          onclick: =>
            if confirm @model.l.get 'general.confirm'
              if isBlocked
                @model.userBlock.unblockByUserId user?.id
              else
                @model.userBlock.blockByUserId user?.id
              @selectedProfileDialogUser.next null
        }
      {
        icon: 'warning'
        $icon: @$flagIcon
        text: if isFlagged \
              then @model.l.get 'profileDialog.isFlagged'
              else @model.l.get 'profileDialog.flag'
        onclick: =>
          @state.set isFlagged: true
          setTimeout =>
            @selectedProfileDialogUser.next null
          , 1000
      }
    ]

  renderItem: (options) =>
    {icon, $icon, $chevronIcon, text, onclick,
      children, isVisible} = options

    {expandedItems} = @state.getValue()

    hasChildren = not _isEmpty children
    isExpanded = expandedItems.indexOf(text) isnt -1

    z 'li.menu-item', {
      onclick: =>
        if hasChildren and isExpanded
          expandedItems = _clone expandedItems
          expandedItems.splice expandedItems.indexOf(text), 1
          @state.set expandedItems: expandedItems
        else if hasChildren
          @state.set expandedItems: expandedItems.concat [text]
        else
          onclick()
    },
      z '.menu-item-link',
        z '.icon',
          z $icon, {
            icon: icon
            color: colors.$primary500
            isTouchTarget: false
          }
        z '.text', text
        if not _isEmpty children
          z '.chevron',
            z $chevronIcon,
              icon: if isExpanded \
                    then 'chevron-up'
                    else 'chevron-down'
              color: colors.$tertiary200Text70
              isTouchTarget: false
      if isExpanded
        z 'ul.menu',
        _map children, @renderItem


  render: =>
    {me, user, group, windowSize, $links} = @state.getValue()

    isMe = user?.id is me?.id

    userOptions = @getUserOptions()
    modOptions = @getModOptions()

    z '.z-profile-dialog', {className: z.classKebab {isVisible: me and user}},
      z @$dialog,
        $content:
          z '.z-profile-dialog_dialog', {
            style:
              maxHeight: "#{windowSize.height}px"
          },
            z '.header',
              z '.avatar',
                z @$avatar, {user, bgColor: colors.$grey100, size: '72px'}
              z '.about',
                z '.name', @model.user.getDisplayName user
                if not _isEmpty user?.groupUser?.roleNames
                  z '.roles', user?.groupUser?.roleNames.join ', '
                z '.links',
                  _map $links, ({$icon, link, type}) =>
                    @router.link z 'a.link', {
                      href: link
                      target: '_system'
                      rel: 'nofollow'
                    },
                      z $icon, {
                        icon: type
                        size: '18px'
                        isTouchTarget: false
                        color: colors.$primary500
                      }
              z '.close',
                z '.icon',
                  z @$closeIcon,
                    icon: 'close'
                    color: colors.$primary500
                    isAlignedTop: true
                    isAlignedRight: true
                    onclick: =>
                      @selectedProfileDialogUser.next null

            z 'ul.menu',
              [
                _map userOptions, @renderItem

                if not _isEmpty modOptions
                  [
                  # z 'ul.content',
                    z '.divider'
                    _map modOptions, @renderItem
                  ]
              ]
