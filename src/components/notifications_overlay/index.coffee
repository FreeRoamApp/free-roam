z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
require 'rxjs/add/operator/switchMap'

Icon = require '../icon'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NotificationsOverlay
  constructor: ({@model, @router, @overlay$, group}) ->
    @$emptyIcon = new Icon()

    @state = z.state
      notifications: group.switchMap (group) =>
        @model.notification.getAll {groupUuid: group.uuid}

  afterMount: =>
    @router.onBack =>
      @overlay$.next null

  beforeUnmount: =>
    @router.onBack null

  render: =>
    {notifications} = @state.getValue()

    isEmpty = _isEmpty notifications

    z '.z-notifications-overlay', {
      className: z.classKebab {isEmpty}
      onclick: =>
        @overlay$.next null
    },
      z '.content', {
        onclick: (e) =>
          e?.stopPropagation()
      },
        if isEmpty
          z '.empty',
            z '.icon',
              z @$emptyIcon,
                icon: 'notifications'
                isTouchTarget: false
                color: colors.$tertiary900Text54
                size: '100px'
            @model.l.get 'notificationsOverlay.empty'
        else
          _map notifications, (notification) =>
            console.log 'not', notification
            z '.notification', {
              onclick: =>
                @overlay$.next null
                @router.go(
                  notification.data.path.key, notification.data.path.params
                  {qs: notification.data.path.qs}
                )
            },
              z '.content',
                z '.title', notification.title
                z '.text', notification.text
              z '.time', DateService.fromNow notification.time
