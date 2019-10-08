z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'

Spinner = require '../../components/spinner'
PrimaryButton = require '../../components/primary_button'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class UnsubscribeEmailPage
  constructor: ({@model, requests, @router, serverData}) ->
    if window?
      requests.switchMap ({req, route}) =>
        RxObservable.fromPromise @model.user.unsubscribeEmail({
          userId: route.params.userId
          token: route.params.token
        }).then =>
          @state.set isUnsubscribed: true
        .catch (err) =>
          console.log err
          @state.set error: 'This email isn\'t subscribed'
          RxObservable.of null

      .take(1)
      .subscribe()

    @$spinner = new Spinner()
    @$returnHomeButton = new PrimaryButton()

    @state = z.state {
      windowSize: @model.window.getSize()
      isUnsubscribed: false
      error: null
    }

  getMeta: =>
    {
      title: @model.l.get 'unsubscribeEmailPage.title'
    }

  render: =>
    {windowSize, isUnsubscribed, error} = @state.getValue()

    z '.p-unsubscribe-email', {
      style:
        height: "#{windowSize.height}px"
    },
      if isUnsubscribed or error
        z '.is-verified',
          error or @model.l.get 'unsubscribeEmail.isUnsubscribed'
          z '.home',
            z @$returnHomeButton,
              text: @model.l.get 'unsubscribeEmail.tapHome'
              onclick: =>
                @router.go 'home'
      else
        [
          z @$spinner
          z '.loading', 'Loading...'
          @router.link z 'a.stuck', {
            href: @router.get 'home'
          }, 'Stuck? Tap to go home'
        ]
