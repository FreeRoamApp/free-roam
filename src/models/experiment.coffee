module.exports = class Experiment
  constructor: ({@cookie}) ->
    expNoProductGuides = @cookie.get 'exp:saveTooltip'
    unless expNoProductGuides
      rand = Math.random()
      expNoProductGuides = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:saveTooltip', expNoProductGuides

    setTimeout ->
      ga? 'send', 'event', 'exp', "saveTooltip:#{expNoProductGuides}"
    , 0

    @experiments =
      saveTooltip: expNoProductGuides

  get: (key) =>
    @experiments[key]
