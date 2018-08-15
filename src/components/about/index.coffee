z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class About
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state
      windowSize: @model.window.getSize()

  render: =>
    {windowSize} = @state.getValue()

    z '.z-about',
      z '.g-grid',
        z '.h1.meet', @model.l.get 'about.meet'
        z '.us',
          z 'img',
            src: "#{config.CDN_URL}/us.jpg"
            width: Math.min(400, windowSize.width - 32 * 2 - 16 * 2)
            height: Math.min(400, windowSize.width - 32 * 2 - 16 * 2)
        z '.divider'
        z 'p', @model.l.get 'about.text1'
        z 'p', @model.l.get 'about.text2'
        z 'p', @model.l.get 'about.text3'
        z 'p',
          @model.l.get 'about.text4'
          ' '
          z 'a', {
            href: 'http://github.com/freeroamapp'
            target: '_system'
          }, @model.l.get 'general.here'
          '.'
        z 'p', @model.l.get 'about.text5'
        z '.divider.clear'
        z 'img.home',
          src: "#{config.CDN_URL}/home.jpg"

        # Goals:
        # 1. Make enough to support ourselves
        # 2. Give others ways to support themselves
        # 3. Encourage others to be respectful of nature and give back
