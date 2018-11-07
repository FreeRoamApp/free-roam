z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Spinner = require '../../components/spinner'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

# generic page that gets loaded from cache for any page w/o a specific shell
module.exports = class ShellPage
  hideDrawer: true

  constructor: ({@model, @router, requests, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$spinner = new Spinner()

    # subscribe so they're in exoid cache
    @state = z.state
      me: @model.user.getMe()
      group: group

  getMeta: ->
    {}

  render: =>
    z '.p-shell',
      z @$appBar, {
        title: ''
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$spinner
