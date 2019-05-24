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

    expDashboard = @cookie.get 'exp:dashboard'
    unless expDashboard
      rand = Math.random()
      expDashboard = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:dashboard', expDashboard

    ga? 'send', 'event', 'exp', "dashboard:#{expDashboard}"

    @experiments =
      control: expControl
      nearbyTooltip: expNearbyTooltip
      dashboard: expDashboard

  get: (key) =>
    @experiments[key]
