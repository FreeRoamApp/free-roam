z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'

Spinner = require '../../components/spinner'
PrimaryButton = require '../../components/primary_button'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class VerifyEmailPage
  constructor: ({@model, requests, @router, serverData}) ->
    if window?
      requests.switchMap ({req, route}) =>
        RxObservable.fromPromise @model.user.verifyEmail({
          userId: route.params.userId
          token: route.params.token
        }).then =>
          @state.set isVerified: true
        .catch (err) =>
          console.log err
          @state.set error: 'The was an error verifying your email'
          RxObservable.of null

      .take(1)
      .subscribe()

    @$spinner = new Spinner()
    @$returnHomeButton = new PrimaryButton()

    @state = z.state {
      windowSize: @model.window.getSize()
      isVerified: false
      error: null
    }

  getMeta: =>
    {
      title: @model.l.get 'verifyEmailpage.title'
    }

  render: =>
    {windowSize, isVerified, error} = @state.getValue()

    z '.p-verify-email', {
      style:
        height: "#{windowSize.height}px"
    },
      if isVerified or error
        z '.is-verified',
          error or @model.l.get 'verifyEmail.isVerified'
          z '.home',
            z @$returnHomeButton,
              text: @model.l.get 'verifyEmail.tapHome'
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
