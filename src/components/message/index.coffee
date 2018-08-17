z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_truncate = require 'lodash/truncate'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Avatar = require '../avatar'
Icon = require '../icon'
ConversationImageView = require '../conversation_image_view'
FormatService = require '../../services/format'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

TITLE_LENGTH = 30
DESCRIPTION_LENGTH = 100

module.exports = class Message
  constructor: (options) ->
    {message, @$body, isGrouped, isMe, @model, @overlay$, @isTextareaFocused
      @selectedProfileDialogUser, @router, @messageBatchesStreams} = options

    @$avatar = new Avatar()
    @$trophyIcon = new Icon()
    @$statusIcon = new Icon()
    @$starIcon = new Icon()
    @$verifiedIcon = new Icon()
    @$fireIcon = new Icon()

    @imageData = new RxBehaviorSubject null
    @$conversationImageView = new ConversationImageView {
      @model
      @imageData
      @overlay$
      @router
    }

    me = @model.user.getMe()

    @state = z.state
      message: message
      isMe: isMe
      isGrouped: isGrouped
      isMeMentioned: me.map (me) ->
        mentions = message?.body?.match? config.MENTION_REGEX
        _find mentions, (mention) ->
          username = mention.replace('@', '').toLowerCase()
          username and username is me?.username
      windowSize: @model.window.getSize()

  render: ({openProfileDialogFn, isTimeAlignedLeft}) =>
    {isMe, message, isGrouped, isMeMentioned, windowSize} = @state.getValue()

    {user, groupUser, time, card, uuid, clientUuid} = message

    groupUpgrades = _filter user?.upgrades, {groupUuid: groupUser?.groupUuid}
    hasBadge = _find groupUpgrades, {upgradeType: 'fireBadge'}
    subBadgeImage = _find(groupUpgrades, {upgradeType: 'twitchSubBadge'})
                    ?.data?.image
    nameColor = (_find(groupUpgrades, {upgradeType: 'nameColorPremium'}) or
      _find(groupUpgrades, {upgradeType: 'nameColorBase'})
    )?.data?.color

    avatarSize = if windowSize.width > 840 \
                 then '40px'
                 else '40px'

    onclick = =>
      unless @isTextareaFocused?.getValue()
        openProfileDialogFn uuid, user, groupUser

    oncontextmenu = ->
      openProfileDialogFn uuid, user, groupUser

    isVerified = user and user.gameStat?.isVerified
    isModerator = groupUser?.roleNames and
                  (
                    groupUser.roleNames.indexOf('mod') isnt -1 or
                    groupUser.roleNames.indexOf('mods') isnt -1
                  )

    z '.z-message', {
      # re-use elements in v-dom. doesn't seem to work with prepending more
      key: "message-#{uuid or clientUuid}"
      className: z.classKebab {isGrouped, isMe, isMeMentioned}
      oncontextmenu: (e) ->
        e?.preventDefault()
        oncontextmenu?()
    },
      z '.avatar', {
        onclick
        style:
          width: avatarSize
      },
        unless isGrouped
          z @$avatar, {
            user
            groupUser
            size: avatarSize
            bgColor: colors.$grey200
          }
        # z '.level', 1

      z '.content',
        unless isGrouped
          z '.author', {onclick},
            if user?.flags?.isStar
              z '.icon',
                z @$starIcon,
                  icon: 'star-tag'
                  color: nameColor or colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            if user?.flags?.isDev
              z '.icon',
                z @$statusIcon,
                  icon: 'dev'
                  color: nameColor or colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            else if user?.flags?.isModerator or isModerator
              z '.icon',
                z @$statusIcon,
                  icon: 'mod'
                  color: nameColor or colors.$tertiary900Text
                  isTouchTarget: false
                  size: '22px'
            z '.name', {
              style:
                color: nameColor
            },
              @model.user.getDisplayName user
            z '.icons',
              if isVerified
                z '.icon',
                  z @$verifiedIcon,
                    icon: 'verified'
                    color: nameColor or colors.$tertiary900Text
                    isTouchTarget: false
                    size: '14px'
              if hasBadge
                z '.icon',
                  z @$fireIcon,
                    icon: 'fire'
                    color: colors.$quaternary500
                    isTouchTarget: false
                    size: '14px'
              else if subBadgeImage
                z '.icon',
                  z 'img.badge',
                    src: subBadgeImage
                    width: 22
                    height: 22
            z '.time', {
              className: z.classKebab {isAlignedLeft: isTimeAlignedLeft}
            },
              if time
              then DateService.fromNow time
              else '...'
            if user?.gameStat
              z '.middot',
                innerHTML: '&middot;'
            if user?.gameStat
              z '.trophies',
                FormatService.number user.gameStat.statValue
                z '.icon',
                  z @$trophyIcon,
                    icon: if user.gameStat.gameKey is 'fortnite' \
                          then 'win'
                          else 'trophy'
                    color: colors.$tertiary900Text54
                    isTouchTarget: false
                    size: '16px'

        z '.body',
          @$body

        if card
          z '.card', {
            onclick: (e) =>
              e?.stopPropagation()
              @router.openLink card.url
          },
            z '.title', _truncate card.title, {length: TITLE_LENGTH}
            z '.description', _truncate card.description, {
              length: DESCRIPTION_LENGTH
            }
