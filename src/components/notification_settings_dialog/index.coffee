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

module.exports = class NotificationSettingsDialog
  constructor: ({@model, @router}) ->
    notificationTypes = {
      global: [
        {
          name: 'Private messages'
          sourceType: 'privateMessage'
        }
        {
          name: 'News'
          sourceType: 'news'
          isTopic: true
        }
        {
          name: 'Social'
          sourceType: 'social'
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

    @state = z.state
      me: me
      isSaving: false
      notificationTypes: me.switchMap (vals) =>
        me = vals

        @model.subscription.getAllByGroupId config.EMPTY_UUID
        .map (subscriptions) =>
          {
            global: _map notificationTypes.global, (type) =>
              isSubscribed = new RxBehaviorSubject(
                _find(subscriptions, {
                  sourceType: type.sourceType
                })?.isEnabled
              )
              _defaults {
                $toggle: new Toggle {
                  isSelected: isSubscribed
                  onToggle: (isSelected) =>
                    method = if isSelected \
                                   then @model.subscription.subscribe
                                   else @model.subscription.unsubscribe
                    method {
                      isTopic: type.isTopic
                      sourceType: type.sourceType
                    }
                }
                isSelected: isSubscribed
              }, type
          }

  render: =>
    {me, notificationTypes, isSaving} = @state.getValue()

    items = []

    z '.z-notification-settings-dialog',
      z @$dialog,
        isVanilla: true
        $content:
          z '.z-notification-settings-dialog_dialog',
            z 'ul.list',
              _map items, ({$icon, icon, text, onclick}) ->
                z 'li.item', {onclick},
                  z '.icon',
                    z $icon,
                      icon: icon
                      isTouchTarget: false
                      color: colors.$primaryMain
                  z '.text', text
            z '.title', @model.l.get 'notificationSettingsDialog.title'
            if not notificationTypes
              @$spinner
            else
              [
                z 'ul.list',
                  _map notificationTypes?.global, (notificationType) =>
                    {name, sourceType, $toggle, isSelected, isTopic} = notificationType
                    z 'li.item',
                      z '.text', name
                      z '.toggle',
                        z $toggle
              ]

        cancelButton:
          text: @model.l.get 'general.close'
          onclick: =>
            @model.overlay.close()
