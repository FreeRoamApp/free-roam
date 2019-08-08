z = require 'zorium'

Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'

if window?
  require './index.styl'

module.exports = class GroupApp
  constructor: ({@model, @router, @group}) ->
    me = @model.user.getMe()

    @spinner = new Spinner()
    @$openInAppButton = new PrimaryButton()
    @$openInBrowserButton = new SecondaryButton()

    @state = z.state {
      group: @group
    }

  render: =>
    {group} = @state.getValue()

    path = @model.group.getPath group, 'groupChat', {@router}
    iosAppUrl = config.IOS_APP_URL
    googlePlayAppUrl = config.GOOGLE_PLAY_APP_URL

    z '.z-group-app', {
      className: z.classKebab {@isImageLoaded}
    },
      if not group?.slug
        z @$spinner
      else [
        z '.open-in-app',
          z '.text', @model.l.get 'groupApp.haveApp'
          z @$openInAppButton,
            text: @model.l.get 'groupApp.openInAppButton'
            onclick: =>
              @model.portal.call 'browser.openWindow', {
                url: "freeroam:/#{path}" # path adds second /
                # target: '_system'
              }

        z '.or', @model.l.get 'general.or'

        z '.open-in-browser',
          z @$openInBrowserButton,
            text: @model.l.get 'groupApp.openInBrowserButton'
            isOutline: true
            onclick: => @router.goPath path

        z '.dont-have',
          z '.text', @model.l.get 'groupApp.dontHaveApp'

          z '.badge.ios', {
            onclick: =>
              @model.portal.call 'browser.openWindow',
                url: iosAppUrl
                target: '_system'
          }
          z '.badge.android', {
            onclick: =>
              @model.portal.call 'browser.openWindow',
                url: googlePlayAppUrl
                target: '_system'
          }
      ]
