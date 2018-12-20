
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
    @setData data # TODO: per-overlay data

    # prevent body scrolling while viewing menu
    document?.body.style.overflow = 'hidden'

  close: (action, response) =>
    overlays = @overlays.getValue()
    {onComplete, onCancel} = overlays.pop()
    if _isEmpty overlays
      overlays = null
    @overlays.next overlays

    if action is 'complete'
      onComplete? response
    else
      onCancel? response

    document?.body.style.overflow = 'auto'
