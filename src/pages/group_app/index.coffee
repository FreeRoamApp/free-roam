z = require 'zorium'
isUuid = require 'isuuid'

GroupApp = require '../../components/group_app'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupAppPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupApp = new GroupApp {
      @model, @router, group
    }

    @state = z.state {group}

  getMeta: =>
    {
      title: @model.l.get 'groupAppPage.title'
    }

  render: =>
    {group} = @state.getValue()

    z '.p-group-app',
      z @$appBar, {
        title: @model.group.getDisplayName group
        $topLeftButton: z @$buttonMenu, {
          color: colors.$header500Icon
        }
      }
      @$groupApp
