z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/combineLatest'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'

Toggle = require '../toggle'
Dialog = require '../dialog'
Icon = require '../icon'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupUserSettingsDialog
  constructor: ({@model, @router, group, @overlay$}) ->
    notificationTypes = [
      {
        name: @model.l.get 'groupSettings.chatMessage'
        key: 'chatMessage'
      }
      {
        name: @model.l.get 'groupSettings.chatMessageMention'
        key: 'chatMention'
      }
      # {
      #   name: 'New announcments'
      #   key: 'announcement'
      # }
    ]

    me = @model.user.getMe()
    @$leaveIcon = new Icon()
    @$dialog = new Dialog()

    groupAndMe = RxObservable.combineLatest(group, me, (vals...) -> vals)

    @state = z.state
      me: me
      group: group
      isSaving: false
      isLeaveGroupLoading: false
      notificationTypes: groupAndMe.switchMap ([group, me]) =>
        @model.groupUser.getMeSettingsByGroupId group.id
        .map (groupUserSettings) ->
          _map notificationTypes, (type) ->
            notifications = _defaults(
              groupUserSettings?.globalNotifications
              config.DEFAULT_NOTIFICATIONS
            )
            isSelected = new RxBehaviorSubject notifications?[type.key]

            _defaults {
              $toggle: new Toggle {isSelected}
              isSelected: isSelected
            }, type

  leaveGroup: =>
    {isLeaveGroupLoading, group} = @state.getValue()

    unless isLeaveGroupLoading
      @state.set isLeaveGroupLoading: true
      @model.group.leaveById group.id
      .then =>
        @state.set isLeaveGroupLoading: false
        @router.go 'home'
        @overlay$.next null

  render: =>
    {me, notificationTypes, group, isLeaveGroupLoading,
      isSaving} = @state.getValue()

    items = []

    # hasAdminPermission = false # TODO
    # unless hasAdminPermission
    #   items = items.concat [
    #     {
    #       $icon: @$leaveIcon
    #       icon: 'subtract-circle'
    #       text: if isLeaveGroupLoading \
    #             then @model.l.get 'general.loading'
    #             else @model.l.get 'groupSettings.leaveGroup'
    #       onclick: @leaveGroup
    #     }
    #   ]

    z '.z-group-user-settings-dialog',
      z @$dialog,
        isVanilla: true
        onLeave: =>
          @overlay$.next null
        # $title: @model.l.get 'general.filter'
        $content:
          z '.z-group-user-settings-dialog_dialog',
            z 'ul.list',
              _map items, ({$icon, icon, text, onclick}) ->
                z 'li.item', {onclick},
                  z '.icon',
                    z $icon,
                      icon: icon
                      isTouchTarget: false
                      color: colors.$primary500
                  z '.text', text
            z '.title', @model.l.get 'general.notifications'
            z 'ul.list',
              _map notificationTypes, ({name, key, $toggle, isSelected}) =>
                z 'li.item',
                  z '.text', name
                  z '.toggle',
                    z $toggle, {
                      onToggle: (isSelected) =>
                        @model.groupUser.updateMeSettingsByGroupId group.id, {
                          globalNotifications:
                            "#{key}": isSelected
                        }
                    }

        cancelButton:
          text: @model.l.get 'general.close'
          onclick: =>
            @overlay$.next null
