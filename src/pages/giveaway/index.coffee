z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Giveaway = require '../../components/giveaway'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GiveawayPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$giveaway = new Giveaway {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'giveawayPage.title'
      description: ''
    }

  render: =>
    z '.p-giveaway',
      z @$appBar, {
        title: @model.l.get 'giveawayPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$giveaway
