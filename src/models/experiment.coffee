module.exports = class Experiment
  constructor: ({@cookie}) ->
    expControl = @cookie.get 'exp:control'
    unless expControl
      rand = Math.random()
      expControl = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:control', expControl

    ga? 'send', 'event', 'exp', "control:#{expControl}"

    expNearbyTooltip = @cookie.get 'exp:nearbyTooltip'
    unless expNearbyTooltip
      rand = Math.random()
      expNearbyTooltip = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:nearbyTooltip', expNearbyTooltip

    ga? 'send', 'event', 'exp', "nearbyTooltip:#{expNearbyTooltip}"

    @experiments =
      control: expControl
      nearbyTooltip: expNearbyTooltip

  get: (key) =>
    @experiments[key]
