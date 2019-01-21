RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class Tooltip
  constructor: ->
    @$tooltip = new RxBehaviorSubject null

  get$: =>
    @$tooltip

  set$: ($tooltip) =>
    @$tooltip.next $tooltip
