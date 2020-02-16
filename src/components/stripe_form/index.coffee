z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Environment = require '../../services/environment'
FormatService = require '../../services/format'
Icon = require '../icon'
Spinner = require '../spinner'
Input = require '../input'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

LOAD_TIME_MS = 2000


module.exports = class StripeForm
  constructor: ({@model, amount, subscriptionInterval}) ->
    @$spinner = new Spinner()
    @numberValue = new RxBehaviorSubject ''
    @cvcValue = new RxBehaviorSubject ''
    @expireMonthValue = new RxBehaviorSubject ''
    @expireYearValue = new RxBehaviorSubject ''
    @$numberInput = new Input
      value: @numberValue
    @$cvcInput = new Input
      value: @cvcValue
    @$expireMonthInput = new Input
      value: @expireMonthValue
    @$expireYearInput = new Input
      value: @expireYearValue

    @state = z.state
      me: @model.user.getMe()
      amount: amount
      subscriptionInterval: subscriptionInterval
      isLoading: false
      error: null
      numberValue: @numberValue
      cvcValue: @cvcValue
      expireMonthValue: @expireMonthValue
      expireYearValue: @expireYearValue

  purchase: =>
    {me} = @state.getValue()
    hasStripeId = me?.flags.hasStripeId

    @model.additionalScript.add(
      'js', 'https://js.stripe.com/v2/'
    )
    .then =>
      Stripe.setPublishableKey config.STRIPE_PUBLISHABLE_KEY
      if hasStripeId
        @onPurchase()
      else
        @onNewStripe()


  onNewStripe: =>
    {isLoading, amount, subscriptionInterval, numberValue, cvcValue,
      expireMonthValue, expireYearValue} = @state.getValue()

    new Promise (resolve, reject) =>
      Stripe.card.createToken {
        number: numberValue
        cvc: cvcValue
        exp_month: expireMonthValue
        exp_year: expireYearValue
      }, (status, response) =>
        if response.error
          @state.set error: response.error.message, isLoading: false
          return reject()

        stripeToken = response.id

        resolve @model.payment.purchase {
          stripeToken, platform: 'web', amount, subscriptionInterval
        }
        .catch (error) =>
          error = try
            JSON.parse error.message
          catch err
            {info: 'Error'}

          @state.set error: error.info, isLoading: false
          throw error

  onPurchase: =>
    {amount, subscriptionInterval} = @state.getValue()
    @model.payment.purchase {
      platform: 'web', amount, subscriptionInterval
    }
    .catch (error) =>
      error = try
        JSON.parse error.message
      catch err
        {info: 'Error'}
      @state.set error: error.info, isLoading: false
      throw error

  render: =>
    {me, error} = @state.getValue()

    isiOSApp = Environment.isNativeApp(config.GAME_KEY) and Environment.isiOS()
    if isiOSApp
      return # against TOS

    # TODO: if native app, prompt them to move to browser

    hasStripeId = me?.flags.hasStripeId

    console.log error

    z '.z-stripe-form',
      if hasStripeId
        z '.stored-info',
          if error
            z 'span.payment-errors', error
          z '.description', @model.l.get 'stripeForm.useSavedInfo'
          z '.edit', {
            onclick: =>
              @model.payment.resetStripeInfo()
          },
            @model.l.get 'stripeForm.changeSavedInfo'
      else
        z 'form.form', {
          onsubmit: (e) =>
            e.preventDefault()
            @purchase()
        },
          if error
            z 'span.payment-errors', error
          z '.form-row',
            z @$numberInput,
              hintText: 'Card Number'
              isFloating: true
              type: 'number'

          z '.form-row',
            z @$cvcInput,
              hintText: 'CVC'
              isFloating: true
              type: 'number'

          z '.form-row.flex',
            z @$expireMonthInput,
              hintText: 'Exp Month'
              isFloating: true
              type: 'number'
            z '.slash', ' / '
            z @$expireYearInput,
              hintText: 'Exp Year'
              isFloating: true
              type: 'number'
          z 'input', # for onsubmit to work
            type: 'submit'
            style:
              display: 'none'
