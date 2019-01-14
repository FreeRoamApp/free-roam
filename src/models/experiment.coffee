module.exports = class Experiment
  constructor: ({@cookie}) ->
    expNoProductGuides = @cookie.get 'exp:noProductGuides'
    unless expNoProductGuides
      rand = Math.random()
      expNoProductGuides = if rand > 0.5 \
                         then 'travelMap'
                         else 'control'
      @cookie.set 'exp:noProductGuides', expNoProductGuides

    setTimeout ->
      ga? 'send', '/event', 'exp', "noProductGuides:#{expNoProductGuides}"
    , 0

    @experiments =
      noProductGuides: expNoProductGuides

  get: (key) =>
    @experiments[key]
