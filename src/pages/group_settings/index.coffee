z = require 'zorium'
isUuid = require 'isuuid'

GroupSettings = require '../../components/group_settings'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupSettingsPage
  isGroup: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    @$groupSettings = new GroupSettings {
      @model, @router, serverData, group
    }

  getMeta: =>
    {
      title: @model.l.get 'groupSettingsPage.title'
    }

  render: =>
    z '.p-group-settings',
      @$groupSettings
