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

    @experiments =
      control: expControl
      profileVideo: expProfileVideo

  get: (key) =>
    @experiments[key]
