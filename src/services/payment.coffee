_map = require 'lodash/map'
_filter = require 'lodash/filter'
_isEmpty = require 'lodash/isEmpty'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Environment = require './environment'
config = require '../config'

class PaymentService
  init: (model, group) ->
    #
    # PAYMENTS
    #
    # consume any pending payments (eg the req to server failed)
    # This can't run simultaneously with getProductDetails
    # because of how IABHelper works on Android. If 2 async requests are
    # called at same time (in our case, getProduct and getPending),
    # the prev one is killed...
    rewardPending = ->
      model.portal.call 'payments.getPending'
      .then (pendingPayments) ->
        console.log 'pending', pendingPayments
        Promise.all _map pendingPayments, (payment) ->
          {platform, receipt, productId, packageName, price} = payment
          platform = if platform is 'android' then 'android' else 'ios'
          model.payment.verify {
            platform: platform
            groupUuid: group.uuid
            receipt: receipt
            productId: productId
            packageName: packageName
            price: price
            isFromPending: true
          }
          .catch -> null
        .then (paymentVerifications) ->
          productIds = _filter _map paymentVerifications, 'productId'

          unless _isEmpty productIds
            model.portal.call 'payments.finishPurchase', {
              productIds: productIds
            }
      .catch (err) ->
        unless err.message is 'Method not found'
          console.log err

    rewardPending()
    .then ->
      # fetch immediately so they're available right when store loads (fetching
      # takes a few seconds)
      platform = Environment.getPlatform {userAgent: navigator.userAgent}
      iapsObservable = model.iap.getAllByPlatform(platform)
      .switchMap((iaps) ->
        if not Environment.isNativeApp 'freeroam'
          return RxObservable.of iaps
        else
          productIds = _map iaps, ({key}) ->
            "#{group.googlePlayAppId}.#{key}"
          RxObservable.fromPromise model.portal.call('payments.getProductDetails', {
            productIds: productIds
          }).then ({iaps} = {}) ->
            iaps = _filter iaps
            _map iaps, (iap) ->
              _defaults(
                iap, _find(iaps, {iapKey: iap.iapKey})
              )
      ).share()
      model.iap.setAllCached iapsObservable
      iapsObservable.take(1).toPromise()
    .then ->
      # try again in case it didn't work the first time
      rewardPending()

module.exports = new PaymentService()
