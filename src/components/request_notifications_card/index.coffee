_map = require 'lodash/map'
z = require 'zorium'

UiCard = require '../ui_card'
PushService = require '../../services/push'

if window?
  require './index.styl'

module.exports = class RequestNotificationsCard
  constructor: ({@model, @isVisible}) ->
    @$uiCard = new UiCard()
    @state = z.state {
      state: 'ask'
    }

  render: =>
    {state} = @state.getValue()

    z '.z-request-notifications-card',
      z @$uiCard,
        isHighlighted: state is 'ask'
        $content:
          if state is 'turnedOn'
            @model.l.get 'requestNotificationsCard.turnedOn'
          else if state is 'noThanks'
            @model.l.get 'requestNotificationsCard.noThanks'
          else
            @model.l.get 'requestNotificationsCard.request'
        cancel:
          if state is 'ask'
            {
              text: @model.l.get 'requestNotificationsCard.cancelText'
              onclick: =>
                @state.set state: 'noThanks'
                localStorage?['hideNotificationCard'] = '1'
            }
        submit:
          text: if state is 'ask' \
                then @model.l.get 'requestNotificationsCard.submit'
                else @model.l.get 'installOverlay.closeButtonText'
          onclick: =>
            if state is 'ask'
              PushService.register {@model}
              localStorage?['hideNotificationCard'] = '1'
              @state.set state: 'turnedOn'
            else
              @isVisible.next false
