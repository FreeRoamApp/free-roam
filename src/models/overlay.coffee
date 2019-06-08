
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'

Environment = require '../services/environment'

module.exports = class Overlay
  constructor: ->
    @overlays = new RxBehaviorSubject null
    @_data = new RxBehaviorSubject null

  getData: =>
    @_data

  setData: (data) =>
    @_data.next data

  get: =>
    @overlays.getValue()

  get$: =>
    @overlays.map (overlays) -> _map overlays, '$'

  open: ($, {data, onComplete, onCancel} = {}) =>
    if Environment.isIos()
      document.activeElement.blur() # hide keyboard
      # setTimeout ->
      #   document.activeElement.blur()
      # , 0

    newOverlays = _filter (@overlays.getValue() or []).concat(
      {$, onComplete, onCancel}
    )
    @overlays.next newOverlays

    window.addEventListener 'backbutton', @closeFromBackButton

    @setData data # TODO: per-overlay data

    # prevent body scrolling while viewing menu
    document?.body.style.overflow = 'hidden'

  closeFromBackButton: (e) =>
    e.stopPropagation()
    @close {isFromBackButton: true}

  close: ({action, response, isFromBackButton} = {}) =>
    overlays = @overlays.getValue()
    if _isEmpty overlays
      return

    window.removeEventListener 'backbutton', @closeFromBackButton

    {onComplete, onCancel} = overlays.pop()
    if _isEmpty overlays
      overlays = null
    @overlays.next overlays

    if action is 'complete'
      onComplete? response
    else
      onCancel? response

    document?.body.style.overflow = 'auto'
