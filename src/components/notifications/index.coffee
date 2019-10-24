z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
Spinner = require '../spinner'
DateService = require '../../services/date'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Notifications
  constructor: ({@model, @router}) ->
    @$notificationsIcon = new Icon()
    @$spinner = new Spinner {@model}

    @state = z.state
      notifications: @model.notification.getAll().map (notifications) ->
        _map notifications, (notification) ->
          {
            notification: notification
            $icon: new Icon()
          }

  beforeUnmount: =>
    @model.exoid.invalidate 'notifications.getAll', {}
    @model.exoid.invalidate 'notifications.getUnreadCount', {}

  render: =>
    {notifications} = @state.getValue()

    z '.z-notifications',
      if notifications and _isEmpty notifications
        z '.no-notifications',
          z @$notificationsIcon,
            icon: 'notifications-none'
            isTouchTarget: false
            size: '80px'
            color: colors.$black26
          z '.message',
            'You\'re all caught up!'
      else if notifications
        z '.g-grid',
          _map notifications, ({notification, $icon}) =>
            isUnread = not notification.isRead

            z '.notification', {
              className: z.classKebab {isUnread}
              onclick: =>
                if notification.data?.path
                  @router.go(
                    notification.data.path.key, notification.data.path.params
                    {qs: notification.data.path.qs}
                  )
            },
              z '.icon',
                z $icon,
                  icon: @model.notification.ICON_MAP[notification.data.type] or
                          'off-topic'
                  color: if isUnread \
                         then colors.$secondaryMain
                         else colors.$tertiary500
                  isTouchTarget: false
              z '.right',
                z '.title', "#{notification.title}: #{notification.text}"
                z '.time', DateService.fromNow notification.time
      else
        @$spinner
