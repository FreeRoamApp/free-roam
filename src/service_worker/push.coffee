RouterService = require '../services/router'
Language = require '../models/language'
config = require '../config'

model =
  l: new Language()

router = new RouterService {
  router: null
  model: model
}

module.exports = class Push
  listen: =>
    self.addEventListener 'push', @onPush

    self.addEventListener 'notificationclick', @onNotificationClick

  onPush: (e) ->
    message = if e.data then e.data.json() else {}
    if message.data?.title
      message = message.data
      message.data = try
        JSON.parse message.data
      catch error
        {}

    if message.data.path
      path = router.get message.data.path.key, message.data.path.params
    else
      path = ''

    e.waitUntil(
      clients.matchAll {
        includeUncontrolled: true
        type: 'window'
      }
      .then (activeClients) ->
        isFocused = activeClients?.some (client) ->
          client.focused

        if not isFocused or contextId isnt message.data.contextId
          self.registration.showNotification 'FreeRoam',
            icon: if message.icon \
                  then message.icon
                  else "#{config.CDN_URL}/android-chrome-192x192.png"
            title: message.title
            # message.text is legacy VAPID
            body: message.message or message.text
            tag: message.data.path
            vibrate: [200, 100, 200]
            data:
              url: "https://#{config.HOST}#{path}"
              path: message.data.path
    )

  onNotificationClick: (e) ->
    e.notification.close()

    e.waitUntil(
      clients.matchAll {
        includeUncontrolled: true
        type: 'window'
      }
      .then (activeClients) ->
        if activeClients.length > 0
          activeClients[0].focus()
          onPushFn? e.notification.data
        else
          clients.openWindow e.notification.data.url
    )
