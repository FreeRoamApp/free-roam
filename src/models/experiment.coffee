module.exports = class Experiment
  constructor: ({@cookie}) ->
    expLfgNewButton = @cookie.get 'exp:lfgNewButton'
    unless expLfgNewButton
      rand = Math.random()
      expLfgNewButton = if rand > 0.5 \
                         then 'big'
                         else 'control'
      @cookie.set 'exp:lfgNewButton', expLfgNewButton
    ga? 'send', 'event', 'exp', 'lfgNewButton', expLfgNewButton

    @experiments =
      lfgNewButton: expLfgNewButton

  get: (key) =>
    @experiments[key]
