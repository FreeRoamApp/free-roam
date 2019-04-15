z = require 'zorium'
_find = require 'lodash/find'
_filter = require 'lodash/filter'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Author
  constructor: ({@model, @router}) ->
    @$statusIcon = new Icon()
    @$starIcon = new Icon()
    @$fireIcon = new Icon()

  render: ({user, groupUser, time, isTimeAlignedLeft, onclick}) =>
    groupUpgrades = _filter user?.upgrades, {groupId: groupUser?.groupId}
    hasBadge = _find groupUpgrades, {upgradeType: 'fireBadge'}
    subBadgeImage = _find(groupUpgrades, {upgradeType: 'twitchSubBadge'})
                    ?.data?.image
    nameColor = (_find(groupUpgrades, {upgradeType: 'nameColorPremium'}) or
      _find(groupUpgrades, {upgradeType: 'nameColorBase'})
    )?.data?.color

    isModerator = groupUser?.roleNames and
                  (
                    groupUser.roleNames.indexOf('mod') isnt -1 or
                    groupUser.roleNames.indexOf('mods') isnt -1
                  )

    z '.z-author', {onclick},
      if user?.username in ['austin', 'rachel']
        z '.icon',
          z @$statusIcon,
            icon: 'dev'
            color: nameColor or colors.$bgText
            isTouchTarget: false
            size: '22px'
      else if user?.flags?.isModerator or isModerator
        z '.icon',
          z @$statusIcon,
            icon: 'mod'
            color: nameColor or colors.$bgText
            isTouchTarget: false
            size: '22px'
      z '.name', {
        style:
          color: nameColor
      },
        @model.user.getDisplayName user
      z '.icons',
        if hasBadge
          z '.icon',
            z @$fireIcon,
              icon: 'fire'
              color: colors.$secondary500
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
