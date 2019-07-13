z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
NewMvum = require '../../components/new_mvum'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NewMvumPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newMvum = new NewMvum {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'newMvumPage.title', {
        replacements:
          prettyType: 'Mvum'
      }
    }

  render: =>
    z '.p-new-mvum',
      z @$appBar, {
        title: @model.l.get 'newMvumPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$newMvum
