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

    expChatTooltip = @cookie.get 'exp:chatTooltip'
    unless expChatTooltip
      rand = Math.random()
      expChatTooltip = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:control', expChatTooltip

    ga? 'send', 'event', 'exp', "control:#{expChatTooltip}"

    @experiments =
      control: expControl
      chatTooltip: expChatTooltip

  get: (key) =>
    @experiments[key]
