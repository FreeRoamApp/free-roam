PortalGun = require 'portal-gun'
_map = require 'lodash/map'

RouterService = require './services/router'
Language = require './models/language'
config = require './config'

# TODO: separate this out into a few files/classes

model =
  l: new Language()

router = new RouterService {
  router: null
  model: model
}

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
        onPushFn? e.notification.data
      else
        clients.openWindow e.notification.data.url
  )

cachesFiles =
  deploy: {
    version: '|HASH|'
    files: [
      'https://fdn.uno/d/scripts/bundle_|HASH|_en.js'
      'https://fdn.uno/d/scripts/bundle_|HASH|.css'
      # 'http://localhost:50341/bundle.js'
    ]
  }
  html: {
    version: '|HASH|'
    files: [
      '/shell'
      '/campground/shell'
    ]
  }
  sprites: {
    version: 1 # bump when changing
    files: [
      'https://fdn.uno/d/images/maps/sprite_2018_11_2.json'
      'https://fdn.uno/d/images/maps/sprite_2018_11_2.png'
      'https://fdn.uno/d/images/maps/sprite_2018_11_2@2x.json'
      'https://fdn.uno/d/images/maps/sprite_2018_11_2@2x.png'
    ]
  }
  mapbox: {
    version: 1 # bump when changing
    files: [
      'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.49.0/mapbox-gl.js'
      'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.49.0/mapbox-gl.css'
    ]
  }

cacheKeys = _map cachesFiles, ({version}, cacheName) ->
  "#{cacheName}:#{version}"

updateCache = ({files, version}, cacheName) ->
  caches.open "#{cacheName}:#{version}"
  .then (cache) ->
    # if any of these fail, all fail
    console.log 'add', "#{cacheName}:#{version}", files
    cache.addAll files

# notifyClients = ->
#   self.clients.matchAll().then (clients) ->
#     console.log 'clients', clients
#     clients.forEach (client) ->
#       message =
#         type: 'refresh'
#       client.postMessage JSON.stringify(message)

self.addEventListener 'install', (event) ->
  event.waitUntil(
    Promise.all _map cachesFiles, updateCache
    # .then notifyClients
    .then ->
      console.log 'caches installed'
      self.skipWaiting()
  )

self.addEventListener 'fetch', (event) ->
  request = event.request
  # console.log 'fetch'
  # console.log event.request.url
  if event.request.url.match /\/campground\/[a-zA-Z0-9-_]/
    request = 'https://staging.freeroam.app/campground/shell'
    # request = 'http://localhost:50340/campground/shell'
  # any other path that isn't a static file
  else if event.request.url.match /(freeroam.app|localhost:50340)([^\.]*)$/i
    request = 'https://staging.freeroam.app/shell'
    # request = 'http://localhost:50340/shell'

  event.respondWith(
    caches.match(request)
    .then (response) ->
      response or fetch(event.request)
  )

self.addEventListener 'activate', (event) ->
  console.log 'activate'
  caches.keys().then (keys) ->
    Promise.all(
      _map keys, (key) ->
        if cacheKeys.indexOf(key) is -1
          caches.delete key
    )
  # set this worker as the active worker for all clients
  event.waitUntil(
    self.clients.claim()
  )




###
# Portal stuff
###

# TODO: set fn for all clients. need to update portal-gun to handle
# responding to all clients better
onPushFn = null
topOnData = (fn) ->
  onPushFn = fn

contextId = null
pushSetContextId = (options) ->
  contextId = options.contextId

deleteHtmlCache = ->
  console.log 'portal update cache', "html:#{cachesFiles.html.version}"
  cache = cachesFiles.html
  updateCache cache, 'html'


portal = new PortalGun()
portal.listen()
portal.on 'top.onData', topOnData
portal.on 'push.setContextId', pushSetContextId
portal.on 'cache.deleteHtmlCache', deleteHtmlCache
portal.on 'cache.getVersion', ->
  console.log 'cache v requested'
  Promise.resolve '|HASH|'
# this doesn't work very well, so just using a postMessage # TODO
# portal.on 'cache.onUpdateAvailable', onUpdateAvailable
