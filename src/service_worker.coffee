PortalGun = require 'portal-gun'

RouterService = require './services/router'
Language = require './models/language'
config = require './config'

model =
  l: new Language()

router = new RouterService {
  router: null
  model: model
}

###
If we want to get the message in the main window (non-service worker) when
it's in the foreground, we can use firebase
https://firebase.google.com/docs/cloud-messaging/js/receive
###
# firebase = require 'firebase/app'
# require 'firebase/messaging'
# firebase.initializeApp {
#   messagingSenderId: config.FIREBASE.MESSAGING_SENDER_ID
# }
# messaging = firebase.messaging()
#
# messaging.setBackgroundMessageHandler (payload) ->
#   console.log 'fbm', payload

###
# Clear cloudflare cache...
###

onPush = null
topOnData = (callback) ->
  onPush = callback

contextId = null
pushSetContextId = (options) ->
  contextId = options.contextId

portal = new PortalGun()
portal.listen()
portal.on 'top.onData', topOnData
portal.on 'push.setContextId', pushSetContextId

self.addEventListener 'install', (e) ->
  self.skipWaiting()

self.addEventListener 'activate', (e) ->
  e.waitUntil self.clients.claim()

self.addEventListener 'push', (e) ->
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
          body: message.message or message.text # message.text is legacy VAPID
          tag: message.data.path
          vibrate: [200, 100, 200]
          data:
            url: "https://#{config.HOST}#{path}"
            path: message.data.path
  )

self.addEventListener 'notificationclick', (e) ->
  e.notification.close()

  e.waitUntil(
    clients.matchAll {
      includeUncontrolled: true
      type: 'window'
    }
    .then (activeClients) ->
      if activeClients.length > 0
        activeClients[0].focus()
        onPush? e.notification.data
      else
        clients.openWindow e.notification.data.url
  )
  return
