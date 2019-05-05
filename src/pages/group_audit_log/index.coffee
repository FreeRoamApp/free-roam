z = require 'zorium'
isUuid = require 'isuuid'

GroupAuditLog = require '../../components/group_audit_log'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupAuditLogPage
  isGroup: true
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$groupAuditLog = new GroupAuditLog {
      @model, @router, serverData, group
    }

  getMeta: =>
    {
      title: @model.l.get 'groupAuditLogPage.title'
    }

  render: =>
    z '.p-group-audit-log',
      z @$appBar, {
        title: @model.l.get 'groupAuditLogPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$groupAuditLog
