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

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: 'Partners'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-partners', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'general.partners'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$partners
