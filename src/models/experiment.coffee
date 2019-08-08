module.exports = class Experiment
  constructor: ({@cookie}) ->
    expDefault = @cookie.get 'exp:control'
    unless expDefault
      rand = Math.random()
      expDefault = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:default', expDefault

    ga? 'send', 'event', 'exp', "default:#{expDefault}"

    @experiments =
      default: expDefault

  get: (key) =>
    @experiments[key]
