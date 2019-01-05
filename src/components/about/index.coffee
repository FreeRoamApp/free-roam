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
        z '.h1.title', @model.l.get 'about.mission'
        z 'p', @model.l.get 'about.mission1'
        z 'ul',
          z 'li', @model.l.get 'about.mission1a'
          z 'li', @model.l.get 'about.mission1b'
          z 'li', @model.l.get 'about.mission1c'
        z '.h1.title', @model.l.get 'about.meet'
        z '.us',
          z 'img',
            src: "#{config.CDN_URL}/us.jpg"
            width: Math.min(400, windowSize.width - 32 * 2 - 16 * 2)
            height: Math.min(400, windowSize.width - 32 * 2 - 16 * 2)
        # z '.divider'
        z 'p', @model.l.get 'about.text1'
        z 'p', @model.l.get 'about.text2'
        z 'p',
          @model.l.get 'about.text3'
          ' '
          z 'a', {
            href: 'http://github.com/freeroamapp'
            target: '_system'
            onclick: ->
              ga? 'send', 'event', 'about', 'github'
          }, @model.l.get 'general.here'
          '.'
        z 'p', @model.l.get 'about.text4'
        z 'p', @model.l.get 'about.text5'
        z 'p',
          @model.l.get 'welcomeDialog.video'
          z 'a', {
            href: '#'
            onclick: (e) =>
              e?.preventDefault()
              @model.portal.call 'browser.openWindow', {
                url: 'https://youtu.be/yKISmxLF5V8'
                target: '_system'
              }
          },
            @model.l.get 'welcomeDialog.watch'

        z '.clear'

        z '.h1.title', @model.l.get 'about.help'
        z 'p', @model.l.get 'about.help1'
        z 'ul',
          z 'li', @model.l.get 'about.help1a'
          z 'li', @model.l.get 'about.help1b'
          z 'li', @model.l.get 'about.help1c'

        z '.divider.clear'

        z 'p.disclaimer', @model.l.get 'about.amazon'
        z 'p.disclaimer', @model.l.get 'about.opencellid'

        # Goals:
        # 1. Make enough to support ourselves
        # 2. Give others ways to support themselves
        # 3. Encourage others to be respectful of nature and give back
