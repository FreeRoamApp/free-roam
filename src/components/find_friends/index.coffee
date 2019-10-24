z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_isEmpty = require 'lodash/isEmpty'

UserList = require '../user_list'
Icon = require '../icon'
Environment = require '../../services/environment'
colors = require '../../colors'

if window?
  require './index.styl'

SEARCH_DEBOUNCE = 300

module.exports = class FindFriends
  constructor: ({@model, @router}) ->

    @value = new RxBehaviorSubject ''

    # TODO: add infinite scroll
    # tried comblineLatest w/ debounce stream and onscrollbottom stream,
    # couldn't get it working
    users = @value.debounceTime(SEARCH_DEBOUNCE).switchMap (query) =>
      if query
        @model.user.search
          query:
            match_phrase_prefix:
              username: query
      else
        RxObservable.of []

    @$icon = new Icon()
    @$clear = new Icon()

    @$userList = new UserList {
      @model, @router, users
    }

    @state = z.state
      value: @value
      users: users

  afterMount: (@$$el) =>
    unless Environment.isIos()
      @$$el.querySelector('.input').focus()

  clear: =>
    @value.next ''
    @$$el.querySelector('.input').focus()

  render: =>
    {value, users} = @state.getValue()

    z '.z-find-friends', {
      style:
        height: "#{window?.innerHeight}px"
    },
      z '.overlay',
        z 'span.left-icon',
          z @$icon,
            icon: 'back'
            # isAlignedTop: true
            # isAlignedLeft: true
            color: colors.$primary900
            onclick: =>
              @model.overlay.close()
        z 'span.right-icon',
          unless _isEmpty value
            z @$clear,
              icon: 'close'
              isAlignedTop: true
              isAlignedRight: true
              color: colors.$primaryMainText
              onclick: @clear
      z 'form.form',
        onsubmit: (e) ->
          e.preventDefault()
          document.activeElement.blur() # hide keyboard
        z 'input.input',
          placeholder: 'Search by username'
          value: value
          onfocus: @open
          focused: 'focused'
          oninput: z.ev (e, $$el) =>
            @value.next $$el.value
      z '.results',
        z @$userList, {
          onclick: (user) =>
            if user.username
              @router.goOverlay 'profile', {
                username: user.username
              }
            else
              @router.goOverlay 'profileById', {
                id: user.id
              }
        }
