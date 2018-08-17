z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
PrimaryInput = require '../primary_input'
PrimaryButton = require '../secondary_button'
FlatButton = require '../flat_button'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SignInDialog
  constructor: ({@model, @router, group}) ->

    @usernameValue = new RxBehaviorSubject ''
    @usernameError = new RxBehaviorSubject null
    @$usernameInput = new PrimaryInput
      value: @usernameValue
      error: @usernameError

    @passwordValue = new RxBehaviorSubject ''
    @passwordError = new RxBehaviorSubject null
    @$passwordInput = new PrimaryInput
      value: @passwordValue
      error: @passwordError

    @emailValue = new RxBehaviorSubject ''
    @emailError = new RxBehaviorSubject null
    @$emailInput = new PrimaryInput
      value: @emailValue
      error: @emailError

    @$submitButton = new FlatButton()
    @$cancelButton = new FlatButton()

    @$twitchButton = new PrimaryButton()
    @$twitchIcon = new Icon()

    @$dialog = new Dialog()

    @state = z.state
      mode: @model.signInDialog.getMode()
      isLoading: false
      group: group

  join: (e) =>
    e?.preventDefault()
    @state.set isLoading: true
    @usernameError.next null
    @emailError.next null
    @passwordError.next null

    @model.auth.join {
      username: @usernameValue.getValue()
      password: @passwordValue.getValue()
      email: @emailValue.getValue()
    }
    .then =>
      @state.set isLoading: false
      # give time for invalidate to work
      setTimeout =>
        @model.user.getMe().take(1).subscribe =>
          @model.signInDialog.loggedIn()
          @model.signInDialog.close()
      , 0
    .catch (err) =>
      err = try
        JSON.parse err.message
      catch
        {}
      errorSubject = switch err.info.field
        when 'email' then @emailError
        when 'password' then @passwordError
        else @usernameError
      errorSubject.next @model.l.get err.info.langKey
      @state.set isLoading: false

  signIn: (e) =>
    e?.preventDefault()
    @state.set isLoading: true
    @usernameError.next null
    @passwordError.next null

    @model.auth.login {
      username: @usernameValue.getValue()
      password: @passwordValue.getValue()
    }
    .then =>
      @state.set isLoading: false
      # give time for invalidate to work
      setTimeout =>
        @model.user.getMe().take(1).subscribe =>
          @model.signInDialog.loggedIn()
          @model.signInDialog.close()
      , 0
    .catch (err) =>
      err = try
        JSON.parse err.message
      catch
        {}
      errorSubject = switch err.info?.field
        when 'password' then @passwordError
        else @usernameError

      errorSubject.next @model.l.get err.info?.langKey
      @state.set isLoading: false

  signInTwitch: =>
    @model.portal.call 'twitch.connect'
    .then (data) =>
      if data?.code
        @model.auth.loginTwitch {
          code: data.code
          idToken: data.idToken
        }
        .then =>
          setTimeout =>
            @model.user.getMe().take(1).subscribe =>
              @model.signInDialog.loggedIn()
              @model.signInDialog.close()
          , 0

  cancel: =>
    @model.signInDialog.cancel()
    @model.signInDialog.close()

  render: ({mode}) =>
    {isLoading, group} = @state.getValue()

    z '.z-sign-in-dialog',
      z @$dialog,
        onLeave: @cancel
        $content:
          z '.z-sign-in-dialog_dialog',
            z '.header',
              z '.title',
                if mode is 'join'
                then @model.l.get 'signInDialog.join'
                else @model.l.get 'signInDialog.signIn'
              z '.button', {
                onclick: =>
                  @model.signInDialog.setMode(
                    if mode is 'join' then 'signIn' else 'join'
                  )
              },
                if mode is 'join'
                then @model.l.get 'general.signIn'
                else @model.l.get 'general.signUp'

            z 'form.content',
              z '.input',
                z @$usernameInput, {
                  hintText: @model.l.get 'general.username'
                }
              if mode is 'join'
                z '.input',
                  z @$emailInput, {
                    hintText: @model.l.get 'general.email'
                  }
              z '.input', {key: 'password-input'},
                z @$passwordInput, {
                  type: 'password'
                  hintText: @model.l.get 'general.password'
                }

              if mode is 'join'
                z '.terms',
                  @model.l.get 'signInDialog.terms', {
                    replacements: {tos: ' '}
                  }
                  z 'a', {
                    href: ''
                    onclick: (e) =>
                      e?.preventDefault()
                      @router.openInAppBrowser {
                        url: "https://#{config.HOST}/policies?isIab=1"
                        key: ''
                      }
                  }, 'TOS'
              z '.actions',
                z '.button',
                  z @$submitButton,
                    text: if isLoading \
                          then @model.l.get 'general.loading'
                          else if mode is 'join'
                          then @model.l.get 'signInDialog.createAccount'
                          else @model.l.get 'general.signIn'
                    colors:
                      cText: colors.$primary500
                    onclick: (e) =>
                      if mode is 'signIn'
                        @signIn e
                      else
                        @join e
                    type: 'submit'
                z '.button',
                  z @$cancelButton,
                    text: @model.l.get 'general.cancel'
                    onclick: @cancel
