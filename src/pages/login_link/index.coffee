z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'

Spinner = require '../../components/spinner'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class LoginLinkPage
  constructor: ({@model, requests, @router, serverData}) ->
    if window?
      requests.switchMap ({req, route}) =>
        @model.loginLink.getByUserIdAndToken(
          route.params.userId
          route.params.token
        )
        .switchMap (loginLink) =>
          # this can fail. if link is expired, won't login
          RxObservable.fromPromise @model.auth.loginLink({
            userId: route.params.userId
            token: route.params.token
          }).then =>
            # can't really invalidate since bots/crawlers may hit this url
            # @model.loginLink.invalidateById route.params.id
            path = loginLink?.data?.path or 'home'
            if window?
              @router?.go path
            path
          .catch =>
            path = loginLink?.data?.path or 'home'
            if window?
              @router?.go path
            path

      .take(1)
      .subscribe()

    @$spinner = new Spinner()

    @state = z.state {
      windowSize: @model.window.getSize()
    }

  getMeta: =>
    {
      title: @model.l.get 'loginLinkpage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-login-link', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$spinner
      z '.loading', 'Loading...'
      @router.link z 'a.stuck', {
        href: @router.get 'home'
      }, 'Stuck? Tap to go home'
