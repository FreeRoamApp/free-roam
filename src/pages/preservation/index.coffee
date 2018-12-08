z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Preservation = require '../../components/preservation'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PreservationPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$preservation = new Preservation {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'preservationPage.title'
    }

  render: =>
    z '.p-preservation',
      z @$appBar, {
        title: @model.l.get 'preservationPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$preservation
