module.exports = class Experiment
  constructor: ({@cookie}) ->
    expTooltips = @cookie.get 'exp:tooltips'
    unless expTooltips
      rand = Math.random()
      expTooltips = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:tooltips', expTooltips
    ga? 'send', 'event', 'exp', "tooltips:#{expTooltips}"

    @experiments =
      tooltips: expTooltips

  get: (key) =>
    @experiments[key]
