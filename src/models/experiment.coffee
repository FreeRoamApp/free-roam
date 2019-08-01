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

    expGuides = @cookie.get 'exp:guides'
    unless expGuides
      rand = Math.random()
      expGuides = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:guides', expGuides

    ga? 'send', 'event', 'exp', "guides:#{expGuides}"

    @experiments =
      default: expDefault
      guides: expGuides

  get: (key) =>
    @experiments[key]
