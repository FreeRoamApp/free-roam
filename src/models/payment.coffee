config = require '../config'

module.exports = class Payment
  namespace: 'payments'

  constructor: ({@auth}) -> null

  purchase: (options) =>
    @auth.call "#{@namespace}.purchase", options, {invalidateAll: true}

  resetStripeInfo: =>
    @auth.call "#{@namespace}.resetStripeInfo", {}, {invalidateAll: true}
