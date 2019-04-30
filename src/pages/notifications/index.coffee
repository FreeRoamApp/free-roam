z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Icon = require '../../components/icon'
NotificationSettingsDialog = require '../../components/notification_settings_dialog'
Notifications = require '../../components/notifications'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NotificationsPage
  constructor: ({@model, @router}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$settingsIcon = new Icon()
    @$notifications = new Notifications {@model, @router}

  getMeta: ->
    {
      title: 'Notifications'
    }

  render: =>
    z '.p-notifications',
      z @$appBar, {
        title: @model.l.get 'general.notifications'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          z @$settingsIcon,
            icon: 'settings'
            color: colors.$header500Icon
            onclick: =>
              @model.overlay.open new NotificationSettingsDialog {
                @model
                @router
              }
      }
      @$notifications
