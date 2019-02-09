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

    expGuides = @cookie.get 'exp:guides'
    unless expGuides
      rand = Math.random()
      expGuides = if rand > 0.5 \
                         then 'visible'
                         else 'control'
      @cookie.set 'exp:guides', expGuides

    ga? 'send', 'event', 'exp', "guides:#{expGuides}"

    @experiments =
      control: expControl
      profileVideo: expProfileVideo
      guides: expGuides

  get: (key) =>
    @experiments[key]
