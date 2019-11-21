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

    expWelcomeOverlay = @cookie.get 'exp:welcomeOverlay'
    unless expWelcomeOverlay
      rand = Math.random()
      expWelcomeOverlay = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:welcomeOverlay', expWelcomeOverlay

    ga? 'send', 'event', 'exp', "welcomeOverlay:#{expWelcomeOverlay}"

    expTripsOnboard = @cookie.get 'exp:tripsOnboard'
    unless expTripsOnboard
      rand = Math.random()
      expTripsOnboard = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:tripsOnboard', expTripsOnboard

    ga? 'send', 'event', 'exp', "tripsOnboard:#{expTripsOnboard}"

    @experiments =
      default: expDefault
      guidesOnboard: expGuidesOnboard # seems to be doing worse, but leaving
      tripsOnboard: expTripsOnboard
      welcomeOverlay: expWelcomeOverlay


  get: (key) =>
    @experiments[key]
