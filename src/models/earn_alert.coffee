RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class EarnAlert
  constructor: ->
    @_reward = new RxBehaviorSubject null

  getReward: =>
    @_reward

  show: (reward) =>
    @_reward.next reward

  hide: =>
    @_reward.next null
