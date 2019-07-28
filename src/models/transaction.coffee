module.exports = class Transaction
  namespace: 'transactions'

  constructor: ({@auth}) -> null

  getAll: =>
    @auth.stream "#{@namespace}.getAll"

  cancelSubscriptionByOrderId: (orderId) =>
    @auth.call "#{@namespace}.cancelSubscriptionByOrderId", {
      orderId
    }, {invalidateAll: true}
