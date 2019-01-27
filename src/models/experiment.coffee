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

    expSaveTooltip = @cookie.get 'exp:saveTooltip'
    unless expSaveTooltip
      rand = Math.random()
      expSaveTooltip = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:saveTooltip', expSaveTooltip

    ga? 'send', 'event', 'exp', "saveTooltip:#{expSaveTooltip}"

    expProfile = @cookie.get 'exp:profile'
    unless expProfile
      rand = Math.random()
      expProfile = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:profile', expProfile

    ga? 'send', 'event', 'exp', "profile:#{expProfile}"

    @experiments =
      control: expControl
      saveTooltip: expSaveTooltip
      profile: expProfile

  get: (key) =>
    @experiments[key]
