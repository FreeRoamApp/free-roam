z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

PrimaryInput = require '../primary_input'
AppBar = require '../app_bar'
Icon = require '../icon'
FlatButton = require '../flat_button'
SecondaryButton = require '../secondary_button'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class SignInOverlay
  # can't use @router here because it's not passed in for requestLoginIfGuest
  constructor: ({@model}) ->

    @$appBar = new AppBar {@model}
    @$closeIcon = new Icon()
    @$toggleButton = new FlatButton()

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

    @$submitButton = new SecondaryButton()
    @$resetPasswordButton = new FlatButton()

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

    z '.z-sign-in-overlay',
      z @$appBar, {
        # title: ''
        bgColor: colors.$secondary400
        $topLeftButton:
          z @$closeIcon,
            icon: 'close'
            color: colors.$secondary400Text
            hasRipple: true
            isAlignedLeft: true
            onclick: =>
              @model.overlay.close()
        $topRightButton:
          z @$toggleButton,
            colors:
              cText: colors.$secondary400Text
            onclick: =>
              @model.overlay.setData(
                if data is 'join' then 'signIn' else 'join'
              )
            text:
              if data is 'join'
              then @model.l.get 'general.signIn'
              else @model.l.get 'general.signUp'

        isFlat: true
      }
      z 'form.content',
        z '.title',
          if data is 'join'
          then @model.l.get 'signInOverlay.join'
          else @model.l.get 'signInOverlay.signIn'
        z '.input',
          z @$usernameInput, {
            hintText: @model.l.get 'general.username'
            autoCapitalize: false
            colors:
              background: null
              ink: colors.$secondary400Text
              underline: colors.$secondary400Text
          }
        if data is 'join' or data is 'reset'
          z '.input',
            z @$emailInput, {
              hintText: @model.l.get 'general.email'
              type: 'email'
              colors:
                background: null
                ink: colors.$secondary400Text
                underline: colors.$secondary400Text
            }
        if data isnt 'reset'
          z '.input', {key: 'password-input'},
            z @$passwordInput, {
              hintText: @model.l.get 'general.password'
              type: 'password'
              colors:
                background: null
                ink: colors.$secondary400Text
                underline: colors.$secondary400Text
            }

        if data is 'join'
          z '.terms',
            @model.l.get 'signInOverlay.terms', {
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
                    then @model.l.get 'signInOverlay.emailResetLink'
                    else if data is 'join'
                    then @model.l.get 'signInOverlay.createAccount'
                    else @model.l.get 'general.signIn'
              isInverted: true
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
                text: @model.l.get 'signInOverlay.resetPassword'
                onclick: =>
                  @model.overlay.setData 'reset'
