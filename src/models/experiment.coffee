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

    expProfileVideo = @cookie.get 'exp:profileVideo'
    unless expProfileVideo
      rand = Math.random()
      expProfileVideo = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:profileVideo', expProfileVideo

    ga? 'send', 'event', 'exp', "profileVideo:#{expProfileVideo}"

    expNewOnboard = @cookie.get 'exp:newOnboard'
    unless expNewOnboard
      rand = Math.random()
      expNewOnboard = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:newOnboard', expNewOnboard

    ga? 'send', 'event', 'exp', "newOnboard:#{expNewOnboard}"

    @experiments =
      control: expControl
      profileVideo: expProfileVideo
      newOnboard: expNewOnboard

  get: (key) =>
    @experiments[key]
