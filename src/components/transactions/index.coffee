z = require 'zorium'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_findLast = require 'lodash/findLast'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
FlatButton = require '../flat_button'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Transactions
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    transactions = @model.transaction.getAll()

    @$cancelButton = new FlatButton()

    @state = z.state
      me: me
      isCancelLoading: false
      subscription: transactions.map (transactions) ->
        subscription = _findLast transactions, (transaction) ->
          transaction.isActiveSubscription
        unless subscription
          return null
        {orderId} = subscription
        subscriptionCount = _filter(transactions, {orderId}).length
        _defaults {
          count: subscriptionCount
          time: DateService.format new Date(subscription.time), 'MMM D'
        }, subscription
      transactions: transactions.map (transactions) ->
        now = new Date()
        _filter _map transactions, (transaction) ->
          unless transaction.isSuccess
            return
          _defaults {
            time: DateService.format new Date(transaction.time), 'MMM D'
          }, transaction

  render: =>
    {me, subscription, transactions, isCancelLoading} = @state.getValue()

    console.log subscription

    z '.z-transactions',
      [
        if subscription
          amount = Math.round(subscription.amountCents / 100)
          [
            z '.title',
              z '.g-grid', @model.l.get 'transactions.yourSubscription'
            z '.subscription',
              z '.g-grid',
                z '.amount', @model.l.get 'transactions.subscriptionMonthly', {
                  replacements: {amount}
                }
                z '.payments', @model.l.get 'transactions.subscriptionPayments', {
                  replacements:
                    payments: subscription.count
                    startTime: subscription.time
                }
                z '.actions',
                  # TODO: 'edit amount'
                  z '.action',
                    z @$cancelButton,
                      text: if isCancelLoading \
                            then @model.l.get 'general.loading'
                            else @model.l.get 'general.cancel'
                      isFullWidth: false
                      onclick: =>
                        @state.set isCancelLoading: true
                        @model.transaction.cancelSubscriptionByOrderId(
                          subscription.orderId
                        )
                        .then =>
                          @state.set isCancelLoading: false
                        .catch (err) =>
                          console.log err
                          @state.set isCancelLoading: false

          ]
        z '.title', z '.g-grid', @model.l.get 'transactions.yourTransactions'
        _map transactions, (transaction) =>
          className = if transaction.subscriptionInterval is 'month' \
                      then 'monthly'
                      else 'one-time'
          z '.transaction',
            z '.g-grid',
              z ".icon.#{className}"
              z '.content',
                z '.name',
                  if transaction.subscriptionInterval is 'month'
                    @model.l.get 'transactions.monthly'
                  else
                    @model.l.get 'transactions.oneTime'
                z '.time', transaction.time
              z '.amount', "$#{Math.round(transaction.amountCents / 100)}"
      ]
