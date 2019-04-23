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
  constructor: ({@model, @router, group}) ->
    @$emptyIcon = new Icon()

    @state = z.state
      notifications: group.switchMap (group) =>
        @model.notification.getAll {groupId: group.id}

  render: =>
    {notifications} = @state.getValue()

    isEmpty = _isEmpty notifications

    z '.z-notifications-overlay', {
      className: z.classKebab {isEmpty}
      onclick: =>
        @model.overlay.close()
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
                color: colors.$bgText54
                size: '100px'
            @model.l.get 'notificationsOverlay.empty'
        else
          _map notifications, (notification) =>
            console.log 'not', notification
            z '.notification', {
              onclick: =>
                @model.overlay.close()
                @router.go(
                  notification.data.path.key, notification.data.path.params
                  {query: notification.data.path.qs}
                )
            },
              z '.content',
                z '.title', notification.title
                z '.text', notification.text
              z '.time', DateService.fromNow notification.time
