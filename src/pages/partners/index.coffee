z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Partners = require '../../components/partners'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PartnersPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$partners = new Partners {@model, @router}

  getMeta: ->
    {
      title: 'Partners'
    }

  render: =>
    z '.p-partners',
      z @$appBar, {
        title: @model.l.get 'general.partners'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$partners
