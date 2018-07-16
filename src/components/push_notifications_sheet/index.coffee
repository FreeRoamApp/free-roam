z = require 'zorium'

Sheet = require '../sheet'
PushService = require '../../services/push'

module.exports = class PushNotificationsSheet
  constructor: ({@model, router}) ->
    @$sheet = new Sheet {
      @model, router, isVisible: @model.pushNotificationSheet.isOpen()
    }

  render: =>
    z '.z-push-notifications-sheet',
      z @$sheet, {
        message: @model.l.get 'pushNotificationsSheet.message'
        icon: 'notifications'
        submitButton:
          text: @model.l.get 'pushNotificationsSheet.submitButtonText'
          onclick: =>
            PushService.register {@model}
            .catch -> null
            .then =>
              @model.pushNotificationSheet.complete()
            @model.pushNotificationSheet.close()
      }
