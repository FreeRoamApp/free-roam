z = require 'zorium'

PrimaryButton = require '../primary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ProfileActions
  constructor: ({@model, @router, user}) ->
    @$messageButton = new PrimaryButton()
    @$friendButton = new PrimaryButton()

    @state = z.state {
      me: @model.user.getMe()
      user
      isMessageLoading: false
      isFriendLoading: false
      isFriends: user.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friend'
          )
        else
          RxObservable.of false
      isFriendRequested: user.switchMap (user) =>
        if user
          @model.connection.isConnectedByUserIdAndType(
            user.id, 'friendRequestSent'
          )
        else
          RxObservable.of false
    }

  render: =>
    {me, user, isMessageLoading, isFriendLoading,
      isFriends, isFriendRequested} = @state.getValue()

    z '.z-profile-actions',
      z '.action',
        z @$messageButton,
          text: if isMessageLoading \
                then @model.l.get 'general.loading'
                else @model.l.get 'general.messageVerb'
          onclick: =>
            @state.set isMessageLoading: true
            @model.conversation.create {
              userIds: [user.id]
            }
            .then (conversation) =>
              @state.set isMessageLoading: false
              @router.go 'conversation', {id: conversation.id}
      z '.action',
        z @$friendButton,
          isOutline: true
          text: if isFriends \
                then @model.l.get 'profile.unfriend'
                else if isFriendRequested
                then @model.l.get 'profile.sentFriendRequest'
                else if isFriendLoading
                then @model.l.get 'general.loading'
                else @model.l.get 'profile.sendFriendRequest'
          onclick: =>
            @model.user.requestLoginIfGuest me
            .then =>
              if isFriends
                isConfirmed = confirm @model.l.get 'profile.confirmUnfriend'
                fn = =>
                  @model.connection.deleteByUserIdAndType(
                    user.id, 'friend'
                  )
              else
                isConfirmed = true
                fn = =>
                  @model.connection.upsertByUserIdAndType(
                    user.id, 'friendRequestSent'
                  )
              if isConfirmed and not isFriendRequested
                @state.set isFriendLoading: true
                fn()
                .then =>
                  @state.set isFriendLoading: false
