_map = require 'lodash/map'
_find = require 'lodash/find'
_sum = require 'lodash/sum'

Environment = require '../services/environment'
config = require '../config'

module.exports = class Cache
  constructor: ->
    @isRecording = false
    @cachesFiles =
      deploy: {
        version: '|HASH|'
        files: [
          'https://fdn.uno/d/scripts/bundle_|HASH|_en.js'
          'https://fdn.uno/d/scripts/vendors~firebase_bundle_|HASH|.js'
          'https://fdn.uno/d/scripts/bundle_|HASH|.css'
          # 'http://localhost:50341/bundle.js'
        ]
      }
      html: {
        version: '|HASH|'
        files: [
          '/cache-shell'
          '/places/cache-shell'
          '/campground/cache-shell'
        ]
      }
      sprites: {
        version: 3 # bump when changing
        files: [
          'https://fdn.uno/d/images/maps/sprite_2019_08_24.json'
          'https://fdn.uno/d/images/maps/sprite_2019_08_24.png'
          'https://fdn.uno/d/images/maps/sprite_2019_08_24@2x.json'
          'https://fdn.uno/d/images/maps/sprite_2019_08_24@2x.png'
        ]
      }
      mapbox: {
        version: 3 # bump when changing
        files: [
          "#{config.SCRIPTS_CDN_URL}/mapbox-gl-1.3.0b1.css"
          "#{config.SCRIPTS_CDN_URL}/mapbox-gl-1.3.0b1.js"
        ]
      }

  updateCache: ({files, version}, cacheName) ->
    caches.open "#{cacheName}:#{version}"
    .then (cache) ->
      # if any of these fail, all fail
      console.log 'add', "#{cacheName}:#{version}", files
      cache.addAll files

  fetchViaNetwork: (request) =>
    fetch(request)
    .then (response) =>
      if @isRecording and request.method is 'GET'
        caches.open 'recorded'
        .then (cache) ->
          cache.put(request, response.clone())
          response
      else
        response

  onInstall: (event) =>
    event.waitUntil(
      Promise.all _map @cachesFiles, @updateCache
      # .then notifyClients
      .then ->
        console.log 'caches installed'
        self.skipWaiting()
    )

  clearByCacheName: (cacheName) ->
    caches.delete cacheName

  getSizeByCacheName: (cacheName) ->
    caches.open cacheName
    .then (cache) ->
      cache.keys().then (keys) ->
        Promise.all _map keys, (key) ->
          cache.match(key).then (response) ->
            response.clone().blob().then (blob) -> blob.size
        .then (sizes) ->
          _sum sizes

  # grab from normal stores (can't use caches.match, because we want to avoid
  # the recorded cache)
  getCacheMatch: (request) =>
    Promise.all _map @cachesFiles, ({version}, cacheName) ->
      caches.open("#{cacheName}:#{version}")
      .then (cache) ->
        cache.match request
    .then (matches) ->
      _find matches, (match) -> Boolean match

  onFetch: (event) =>
    # xhr upload progress listener doesn't work w/o this
    # https://github.com/w3c/ServiceWorker/issues/1141
    if event.request.method is 'POST' and event.request.url.match(
        /\/upload[^a-zA-Z]/i
    )
      return

    request = event.request
    # console.log 'fetch'
    # console.log event.request.url
    if event.request.url.match /\/campground\/[a-zA-Z0-9-_]/
      request = 'https://freeroam.app/campground/cache-shell'
      # request = 'https://staging.freeroam.app/campground/cache-shell'
      # request = 'http://localhost:50340/campground/cache-shell'
    else if event.request.url.match /(:\/\/freeroam.app|localhost:50340)(\/?$|\/places)/i
      request = 'https://freeroam.app/places/cache-shell'
      # request = 'https://staging.freeroam.app/campground/cache-shell'
      # request = 'http://localhost:50340/campground/cache-shell'
    # any other path that isn't a static file
    else if event.request.url.match /(:\/\/freeroam.app|localhost:50340)([^\.]*)$/i
      request = 'https://freeroam.app/cache-shell'
      # request = 'https://staging.freeroam.app/cache-shell'
      # request = 'http://localhost:50340/cache-shell'

    event.respondWith(
      @getCacheMatch request
      .catch (err) ->
        console.log 'cache match err', err
        null
      .then (response) =>
        response or @fetchViaNetwork event.request
      .catch (err) -> # throws when offline
        console.log 'fetch err.....', err
        return caches.open('recorded') # user-recorded requests for offline mode
        .then (cache) ->
          cache.match event.request
          .then (recordedCache) ->
            unless recordedCache
              console.log 'throwing'
              throw err
            recordedCache
    )

  onActivate: (event) =>
    cacheKeys = _map @cachesFiles, ({version}, cacheName) ->
      "#{cacheName}:#{version}"
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

  listen: =>
    self.addEventListener 'install', @onInstall

    self.addEventListener 'fetch', @onFetch

    self.addEventListener 'activate', @onActivate
