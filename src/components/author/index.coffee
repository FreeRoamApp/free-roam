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
    @$karmaIcon = new Icon()
    @$supporterIcon = new Icon()

  render: ({user, groupUser, time, isTimeAlignedLeft, onclick}) =>
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
            color: colors.$bgText
            isTouchTarget: false
            size: '22px'
      else if user?.flags?.isModerator or isModerator
        z '.icon',
          z @$statusIcon,
            icon: 'mod'
            color: colors.$bgText
            isTouchTarget: false
            size: '22px'
      z '.icons',
        if user?.flags?.isSupporter
          z '.icon',
            z @$supporterIcon,
              icon: 'heart'
              color: colors.$red500
              isTouchTarget: false
              size: '14px'
        z '.icon',
          z @$karmaIcon,
            icon: 'karma'
            color: colors.$secondary500
            isTouchTarget: false
            size: '14px'
        z '.text', user?.karma or 0
      z '.name',
        @model.user.getDisplayName user
      z '.time', {
        className: z.classKebab {isAlignedLeft: isTimeAlignedLeft}
      },
        if time
        then DateService.fromNow time
        else '...'
