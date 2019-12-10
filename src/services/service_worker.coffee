if window?
  PortalGun = require 'portal-gun'

config = require '../config'
PushService = require './push'
Environment = require './environment'

class ServiceWorkerService
  register: ({model}) =>
    if Environment.isScreenshotter()
      console.log 'SKIP SERVICE WORKER' # don't need for screenshotter
      return
    try
      console.log 'registering service worker...'
      navigator.serviceWorker?.register '/service_worker.js'
      .then (registration) =>
        console.log 'service worker registered'
        PushService.setFirebaseServiceWorker registration

        @hasActiveServiceWorker = Boolean registration.active

        @listenForWaitingServiceWorker registration, (registration) =>
          @handleUpdate registration, {model}
      .catch (err) ->
        console.log 'sw promise err', err
        window.fetch config.API_URL + '/log',
          method: 'POST'
          headers:
            'Content-Type': 'text/plain' # Avoid CORS preflight
          body: JSON.stringify
            event: 'client_error'
            trace: null # trace
            error: 'SERVICE WORKER' + String(err)

    catch err
      console.log 'sw err', err

  handleUpdate: (registration, {model}) =>
    if @hasActiveServiceWorker
      model.statusBar.open {
        text: model.l.get 'status.newVersion'
        type: 'snack'
        action:
          icon: 'refresh'
          onclick: ->
            window.location.reload()
      }
    # PushService.setFirebaseServiceWorker registration

    # TODO: portal is no longer connected at this point... need to reconnect
    # to new service worker
    # model.portal.updateServiceWorker registration
    #
    # model.portal.call 'cache.getVersion'
    # .then (version) ->
    #   if version isnt '|HASH|' # replaced by gulp build
    #     model.statusBar.open {
    #       text: model.l.get 'status.newVersion'
    #     }

  # https://redfin.engineering/how-to-fix-the-refresh-button-when-using-service-workers-a8e27af6df68
  ###
  could detect service worker changes here, then request refresh
  ###
  listenForWaitingServiceWorker: (reg, callback) ->
    awaitStateChange = ->
      reg.installing.addEventListener 'statechange', ->
        if this.state is 'installed'
          callback reg

    unless reg
      return
    if reg.waiting
      return callback(reg)
    if reg.installing
      awaitStateChange()
    reg.addEventListener 'updatefound', awaitStateChange

module.exports = new ServiceWorkerService()
