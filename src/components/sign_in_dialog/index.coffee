z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Dialog = require '../dialog'
PrimaryInput = require '../primary_input'
FlatButton = require '../flat_button'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SignInDialog
  # can't use @router here because it's not passed in for requestLoginIfGuest
  constructor: ({@model}) ->

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
    @$resetPasswordButton = new FlatButton()
    @$cancelButton = new FlatButton()

    @$dialog = new Dialog {
      onLeave: @cancel
    }

    @state = z.state
      data: @model.overlay.getData()
      isLoading: false
      hasError: false

  beforeUnmount: =>
    @state.set hasError: false

  join: (e) =>
    e?.preventDefault()
    @state.set isLoading: true, hasError: false
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
          @model.overlay.close {action: 'complete'}
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

  reset: (e) =>
    e?.preventDefault()
    @state.set isLoading: true, hasError: false
    @usernameError.next null
    @emailError.next null

    @model.auth.resetPassword {
      username: @usernameValue.getValue()
      email: @emailValue.getValue()
    }
    .then =>
      @state.set isLoading: false
      @model.overlay.close {action: 'complete'}
    .catch (err) =>
      err = try
        JSON.parse err.message
      catch
        {}
      errorSubject = switch err.info.field
        when 'email' then @emailError
        when 'username' then @usernameError
        else @usernameError
      errorSubject.next @model.l.get err.info.langKey
      @state.set isLoading: false

  signIn: (e) =>
    e?.preventDefault()
    @state.set isLoading: true, hasError: false
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
          @model.overlay.close {action: 'complete'}
      , 0
    .catch (err) =>
      @state.set hasError: true
      err = try
        JSON.parse err.message
      catch
        {}
      errorSubject = switch err.info?.field
        when 'password' then @passwordError
        else @usernameError

      errorSubject.next @model.l.get err.info?.langKey
      @state.set isLoading: false

  cancel: =>
    @model.overlay.close 'cancel'

  render: =>
    {isLoading, data, hasError} = @state.getValue()

    z '.z-sign-in-dialog',
      z @$dialog,
        $content:
          z '.z-sign-in-dialog_dialog',
            z '.header',
              z '.title',
                if data is 'join'
                then @model.l.get 'signInDialog.join'
                else @model.l.get 'signInDialog.signIn'
              z '.button', {
                onclick: =>
                  @model.overlay.setData(
                    if data is 'join' then 'signIn' else 'join'
                  )
              },
                if data is 'join'
                then @model.l.get 'general.signIn'
                else @model.l.get 'general.signUp'

            z 'form.content',
              z '.input',
                z @$usernameInput, {
                  hintText: @model.l.get 'general.username'
                  autoCapitalize: false
                }
              if data is 'join' or data is 'reset'
                z '.input',
                  z @$emailInput, {
                    hintText: @model.l.get 'general.email'
                    type: 'email'
                  }
              if data isnt 'reset'
                z '.input', {key: 'password-input'},
                  z @$passwordInput, {
                    type: 'password'
                    hintText: @model.l.get 'general.password'
                  }

              if data is 'join'
                z '.terms',
                  @model.l.get 'signInDialog.terms', {
                    replacements: {tos: ' '}
                  }
                  z 'a', {
                    href: "https://#{config.HOST}/policies"
                    target: '_system'
                    onclick: (e) =>
                      e.preventDefault()
                      @model.portal.call 'browser.openWindow', {
                        url: "https://#{config.HOST}/policies"
                      }
                  }, 'TOS'
              z '.actions',
                z '.button',
                  z @$submitButton,
                    text: if isLoading \
                          then @model.l.get 'general.loading'
                          else if data is 'reset'
                          then @model.l.get 'signInDialog.emailResetLink'
                          else if data is 'join'
                          then @model.l.get 'signInDialog.createAccount'
                          else @model.l.get 'general.signIn'
                    colors:
                      cText: colors.$primaryMain
                    onclick: (e) =>
                      if data is 'reset'
                        @reset e
                      else if data is 'join'
                        @join e
                      else
                        @signIn e
                    type: 'submit'
                if hasError and data is 'signIn'
                  z '.button',
                    z @$resetPasswordButton,
                      text: @model.l.get 'signInDialog.resetPassword'
                      onclick: =>
                        @model.overlay.setData 'reset'
                z '.button',
                  z @$cancelButton,
                    text: @model.l.get 'general.cancel'
                    onclick: @cancel
