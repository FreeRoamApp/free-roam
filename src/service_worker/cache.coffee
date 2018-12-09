_map = require 'lodash/map'
_find = require 'lodash/find'
_sum = require 'lodash/sum'

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
          '/shell'
          '/campground/shell'
        ]
      }
      sprites: {
        version: 2 # bump when changing
        files: [
          'https://fdn.uno/d/images/maps/sprite_2018_11_17.json'
          'https://fdn.uno/d/images/maps/sprite_2018_11_17.png'
          'https://fdn.uno/d/images/maps/sprite_2018_11_17@2x.json'
          'https://fdn.uno/d/images/maps/sprite_2018_11_17@2x.png'
        ]
      }
      mapbox: {
        version: 2 # bump when changing
        files: [
          "#{config.SCRIPTS_CDN_URL}/mapbox-gl-0.51.0.css"
          "#{config.SCRIPTS_CDN_URL}/mapbox-gl-0.51.0.js"
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
    request = event.request
    # console.log 'fetch'
    # console.log event.request.url
    if event.request.url.match /\/campground\/[a-zA-Z0-9-_]/
      request = 'https://freeroam.app/campground/shell'
      # request = 'https://staging.freeroam.app/campground/shell'
      # request = 'http://localhost:50340/campground/shell'
    # any other path that isn't a static file
    else if event.request.url.match /(freeroam.app|localhost:50340)([^\.]*)$/i
      request = 'https://freeroam.app/shell'
      # request = 'https://staging.freeroam.app/shell'
      # request = 'http://localhost:50340/shell'

    event.respondWith(
      @getCacheMatch request
      .then (response) =>
        response or @fetchViaNetwork event.request
      .catch (err) ->
        caches.open('recorded')
        .then (cache) ->
          cache.match event.request
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
