z = require 'zorium'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/operator/combineLatest'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switchMap'

Toggle = require '../toggle'
Dialog = require '../dialog'
Icon = require '../icon'
Spinner = require '../spinner'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupUserSettingsDialog
  constructor: ({@model, @router, group, conversation}) ->
    notificationTypes = {
      group: [
        {
          name: @model.l.get 'groupSettings.chatMessage'
          sourceType: 'groupMessage'
          isTopic: true
        }
        {
          name: @model.l.get 'groupSettings.chatMessageMention'
          sourceType: 'groupMention'
        }
      ]
      channel: [
        {
          name: @model.l.get 'groupSettings.chatMessage'
          sourceType: 'channelMessage'
          groupSourceType: 'groupMessage' # either needs to be on
          isTopic: true
        }
        {
          name: @model.l.get 'groupSettings.chatMessageMention'
          sourceType: 'channelMention'
          groupSourceType: 'groupMention' # either needs to be on
        }
      ]
    }

    me = @model.user.getMe()
    @$leaveIcon = new Icon()
    @$spinner = new Spinner()
    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }

    groupAndConversationAndMe = RxObservable.combineLatest(
      group, conversation, me, (vals...) -> vals
    )

    @state = z.state
      me: me
      group: group
      conversation: conversation
      isSaving: false
      isLeaveGroupLoading: false
      notificationTypes: groupAndConversationAndMe.switchMap (vals) =>
        [group, conversation, me] = vals

        @model.subscription.getAllByGroupId group.id
        .map (subscriptions) ->
          {
            group: _map notificationTypes.group, (type) ->
              isSubscribed = new RxBehaviorSubject(
                _find(subscriptions, {
                  sourceType: type.sourceType
                })?.isEnabled
              )
              _defaults {
                $toggle: new Toggle {isSelected: isSubscribed}
                isSelected: isSubscribed
              }, type
            channel: _map notificationTypes.channel, (type) ->
              isSubscribed = new RxBehaviorSubject(
                (
                  _find(subscriptions, {sourceType: type.sourceType, sourceId: conversation.id})?.isEnabled or
                  _find(subscriptions, {sourceType: type.groupSourceType})?.isEnabled
                )
              )
              _defaults {
                $toggle: new Toggle {isSelected: isSubscribed}
                isSelected: isSubscribed
              }, type
          }

  leaveGroup: =>
    {isLeaveGroupLoading, group} = @state.getValue()

    unless isLeaveGroupLoading
      @state.set isLeaveGroupLoading: true
      @model.group.leaveById group.id
      .then =>
        @state.set isLeaveGroupLoading: false
        @router.go 'home'
        @model.overlay.close()

  render: =>
    {me, notificationTypes, group, conversation, isLeaveGroupLoading,
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
            z '.title', @model.l.get 'groupSettings.groupNotifications'
            if not notificationTypes
              @$spinner
            else
              [
                z 'ul.list',
                  _map notificationTypes?.group, (notificationType) =>
                    {name, sourceType, $toggle, isSelected, isTopic} = notificationType
                    z 'li.item',
                      z '.text', name
                      z '.toggle',
                        z $toggle, {
                          onToggle: (isSelected) =>
                            method = if isSelected \
                                     then @model.subscription.subscribe
                                     else @model.subscription.unsubscribe
                            method {
                              groupId: group.id
                              isTopic: isTopic
                              sourceType: sourceType
                            }
                        }
                z '.title', @model.l.get 'groupSettings.channelNotifications'
                z 'ul.list',
                  _map notificationTypes?.channel, (notificationType) =>
                    {name, sourceType, $toggle, isSelected, isTopic} = notificationType
                    z 'li.item',
                      z '.text', name
                      z '.toggle',
                        z $toggle, {
                          onToggle: (isSelected) =>
                            method = if isSelected \
                                     then @model.subscription.subscribe
                                     else @model.subscription.unsubscribe
                            method {
                              groupId: group.id
                              isTopic: isTopic
                              sourceType: sourceType
                              sourceId: conversation.id
                            }
                        }
              ]

        cancelButton:
          text: @model.l.get 'general.close'
          onclick: =>
            @model.overlay.close()
