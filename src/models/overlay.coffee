
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'

module.exports = class Overlay
  constructor: ->
    @overlays = new RxBehaviorSubject null
    @_data = new RxBehaviorSubject null

  getData: =>
    @_data

  setData: (data) =>
    @_data.next data

  get$: =>
    @overlays.map (overlays) -> _map overlays, '$'

  open: ($, {data, onComplete, onCancel} = {}) =>
    @overlays.next _filter (@overlays.getValue() or []).concat(
      {$, onComplete, onCancel}
    )

    window.location.hash = '#overlay' # for back button to work
    window.addEventListener 'popstate', @closeFromBackButton

    @setData data # TODO: per-overlay data

    # prevent body scrolling while viewing menu
    document?.body.style.overflow = 'hidden'

  closeFromBackButton: (e) =>
    e.stopPropagation()
    @close {isFromBackButton: true}

  close: ({action, response, isFromBackButton} = {}) =>
    overlays = @overlays.getValue()

    window.removeEventListener 'popstate', @closeFromBackButton
    unless isFromBackButton
      window.history.back()

    {onComplete, onCancel} = overlays.pop()
    if _isEmpty overlays
      overlays = null
    @overlays.next overlays

    if action is 'complete'
      onComplete? response
    else
      onCancel? response

    document?.body.style.overflow = 'auto'
