z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Tos = require '../../components/tos'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TosPage
  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$backButton = new ButtonBack {@model, @router}
    @$tos = new Tos {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'tosPage.title'
      description: @model.l.get 'tosPage.title'
    }

  render: =>
    z '.p-tos',
      z @$appBar, {
        title: @model.l.get 'tosPage.title'
        $topLeftButton: z @$backButton, {color: colors.$header500Icon}
      }
      @$tos
