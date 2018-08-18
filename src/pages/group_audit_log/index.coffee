z = require 'zorium'
isUuid = require 'isuuid'

GroupAuditLog = require '../../components/group_audit_log'
AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupAuditLogPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$groupAuditLog = new GroupAuditLog {
      @model, @router, serverData, group
    }

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'groupAuditLogPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-group-audit-log', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'groupAuditLogPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$groupAuditLog
