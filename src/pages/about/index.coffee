z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
About = require '../../components/about'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class AboutPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$about = new About {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'drawer.about'
      description: @model.l.get 'about.mission'
    }

  render: =>
    z '.p-about',
      z @$appBar, {
        title: @model.l.get 'drawer.about'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$about
