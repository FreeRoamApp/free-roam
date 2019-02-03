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

    @experiments =
      control: expControl
      saveTooltip: expSaveTooltip

  get: (key) =>
    @experiments[key]
