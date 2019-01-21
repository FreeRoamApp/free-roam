z = require 'zorium'
_map = require 'lodash/map'

Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# adding to DOM directly is faster than doing a full re-render

ANIMATION_TIME_MS = 1550

module.exports = class EarnAlert
  type: 'Widget'

  constructor: ({@model}) ->
    @hasMounted = false

  afterMount: (@$$el) =>
    unless @hasMounted
      @hasMounted = true
      $$alert = document.createElement 'div'
      $$alert.className = 'reward'
      @mountDisposable = @model.earnAlert.getReward().subscribe ({rewards, x, y} = {}) =>
        rewardStrs = _map rewards, (reward) ->
          if reward.currencyType is 'karma'
            "+#{reward.currencyAmount}karma"
          # else
          #   itemKey = reward.currencyItemKey
          #   dir = itemKey?.split('_')?[0]
          #   imgUrl = "#{config.CDN_URL}/items/#{dir}/currency/#{itemKey}.png"
          #   "+#{reward.currencyAmount} " +
          #     "<img src='#{imgUrl}' class='image' width='16' height='16'>"
        $$alert.innerHTML = rewardStrs.join '  '
        if x <= window.innerWidth / 2
          $$alert.style.left = x + 'px'
          $$alert.style.right = 'auto'
        else
          $$alert.style.left = 'auto'
          $$alert.style.right = window.innerWidth - x + 'px'
        $$alert.style.top = y + 'px'
        @$$el.appendChild $$alert
        setTimeout =>
          @$$el.removeChild $$alert
        , ANIMATION_TIME_MS

  # always in dom in app
  # beforeUnmount: =>
  #   @mountDisposable?.unsubscribe()

  render: ->
    z '.z-earn-alert', {key: 'earn-alert'}
