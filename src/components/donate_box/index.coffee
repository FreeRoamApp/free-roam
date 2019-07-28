z = require 'zorium'
_map = require 'lodash/map'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
PrimaryButton = require '../primary_button'
StripeForm = require '../stripe_form'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Donate
  constructor: ({@model, @router}) ->
    @amount = new RxBehaviorSubject 5
    @subscriptionInterval = new RxBehaviorSubject null

    @$stripeForm = new StripeForm {@model, @amount, @subscriptionInterval}
    @$donateButton = new PrimaryButton()
    @$thanksIcon = new Icon()

    @state = z.state {
      me: @model.user.getMe()
      selectedAmount: '5'
      amount: @amount
      subscriptionInterval: @subscriptionInterval
      step: 'amount' # amount, card, thanks
      isLoading: false
    }

  render: =>
    {me, subscriptionInterval, selectedAmount, amount, step,
      isLoading} = @state.getValue()

    amountLines = [
      {
        '5': '$5'
        '10': '$10'
        '20': '$20'
      }
      {
        '30': '$30'
        'other': @model.l.get 'donate.otherAmount'
      }
    ]

    z '.z-donate-box',
      if step isnt 'thanks'
        z '.tap-tabs',
          z '.tab', {
            className: z.classKebab {isSelected: not subscriptionInterval}
            onclick: => @subscriptionInterval.next null
          },
            @model.l.get 'donate.giveOnce'
          z '.tab', {
            className:
              z.classKebab {isSelected: subscriptionInterval is 'month'}
            onclick: => @subscriptionInterval.next 'month'
          },
            @model.l.get 'donate.monthly'
      z '.donation-box',
        if step is 'thanks'
          z '.thanks',
            z '.icon',
              z @$thanksIcon,
                icon: 'check'
                isTouchTarget: false
                size: '52px'
                color: colors.$primary500
            z '.title', @model.l.get 'donate.thanks', {
              replacements:
                name: @model.user.getDisplayName(me)
            }
            z '.description',
              if subscriptionInterval is 'month'
                @model.l.get 'donate.thanksDescriptionMonthly', {
                  replacements:
                    amount: amount
                }
              else
                @model.l.get 'donate.thanksDescription', {
                  replacements:
                    amount: amount
                }
        else
          [
            z '.title',
              if step is 'amount'
                @model.l.get 'donate.donationBoxTitle'
              else
                [
                  if subscriptionInterval is 'month'
                    @model.l.get 'donate.donationBoxCardMonthlyTitle', {
                      replacements:
                        amount: amount
                    }
                  else
                    @model.l.get 'donate.donationBoxCardTitle', {
                      replacements:
                        amount: amount
                    }
                  z 'span.edit', {
                    onclick: =>
                      @state.set step: 'amount'
                  },
                    @model.l.get 'donate.editAmount'
                ]
            z '.content',
              if step is 'amount'
                [
                  z '.amounts',
                    _map amountLines, (amounts) =>
                      z '.amounts-line',
                        _map amounts, (amount, key) =>
                          if key is 'other'
                            z 'input.amount.input#donation-amount',
                              className: z.classKebab {isSelected: selectedAmount is key}
                              attributes:
                                type: 'number'
                              onclick: =>
                                @state.set selectedAmount: key
                                @amount.next 0
                              placeholder: @model.l.get 'donate.otherAmount'
                          else
                            z '.amount', {
                              className: z.classKebab {isSelected: selectedAmount is key}
                              onclick: =>
                                @state.set selectedAmount: key
                                @amount.next key
                            },
                              amount
                  z @$donateButton,
                    text: @model.l.get 'general.donate'
                    onclick: =>
                      if selectedAmount is 'other'
                        value = document.getElementById('donation-amount').value
                        unless value
                          return
                        @state.set {amount: value}
                      @state.set step: 'card'
                ]
              else
                buttonLangKey = if subscriptionInterval is 'month' \
                                then 'donate.donateAmountMonthly'
                                else 'donate.donateAmount'

                [
                  z '.stripe-form',
                    @$stripeForm
                  z '.donate-button',
                    z @$donateButton,
                      text:
                        if isLoading
                          @model.l.get 'general.loading'
                        else
                          @model.l.get buttonLangKey, {
                            replacements: {amount}
                          }
                      onclick: =>
                        @state.set {isLoading: true}
                        @model.user.requestLoginIfGuest me
                        .then =>
                          @$stripeForm.purchase()
                          .then =>
                            @state.set {isLoading: false, step: 'thanks'}
                          .catch =>
                            @state.set {isLoading: false}
                ]
          ]
