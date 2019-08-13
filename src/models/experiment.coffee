module.exports = class Experiment
  # TODO: have exp cookies only last ~ a month
  constructor: ({@cookie}) ->
    expDefault = @cookie.get 'exp:default'
    unless expDefault
      rand = Math.random()
      expDefault = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:default', expDefault

    ga? 'send', 'event', 'exp', "default:#{expDefault}"

    expGuidesOnboard = @cookie.get 'exp:guidesOnboard'
    unless expGuidesOnboard
      rand = Math.random()
      expGuidesOnboard = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:guidesOnboard', expGuidesOnboard

    ga? 'send', 'event', 'exp', "guidesOnboard:#{expGuidesOnboard}"

    @experiments =
      default: expDefault
      guidesOnboard: expGuidesOnboard

  get: (key) =>
    @experiments[key]
