module.exports = class Experiment
  constructor: ({@cookie}) ->
    expOnboard = @cookie.get 'exp:onboard'
    unless expOnboard
      rand = Math.random()
      expOnboard = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:onboard', expOnboard
    ga? 'send', 'event', 'exp', "onboard:#{expOnboard}"

    expTooltips = @cookie.get 'exp:tooltips'
    unless expTooltips
      rand = Math.random()
      expTooltips = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:tooltips', expTooltips
    ga? 'send', 'event', 'exp', "tooltips:#{expTooltips}"

    @experiments =
      onboard: expOnboard
      tooltips: expTooltips

  get: (key) =>
    @experiments[key]
