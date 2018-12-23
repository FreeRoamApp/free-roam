module.exports = class Experiment
  constructor: ({@cookie}) ->
    expTravelMap = @cookie.get 'exp:travelMap'
    unless expTravelMap
      rand = Math.random()
      expTravelMap = if rand > 0.5 \
                         then 'bottomBar'
                         else 'control'
      @cookie.set 'exp:travelMap', expTravelMap
    ga? 'send', 'event', 'exp', "travelMap:#{expTravelMap}"

    @experiments =
      travelMap: expTravelMap

  get: (key) =>
    @experiments[key]
