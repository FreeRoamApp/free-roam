z = require 'zorium'
_defaults = require 'lodash/defaults'

Message = require '../message'
ProfileDialog = require '../profile_dialog'

if window?
  require './index.styl'

module.exports = class ConversationMessage
  constructor: (options) ->
    {@messageBatchesStreams, @model, @router,
      @isTextareaFocused} = options
    @$message = new Message options

  render:  =>
    z '.z-conversation-message',
      z @$message, {
        openProfileDialogFn: (id, user, groupUser) =>
          @model.overlay.open new ProfileDialog {
            @model
            @router
            user
            groupUser
            onDeleteMessage: =>
              @model.conversationMessage.deleteById id
              .then =>
                @messageBatchesStreams.take(1).toPromise()
            onDeleteMessagesLast7d: =>
              @model.conversationMessage.deleteAllByGroupIdAndUserId(
                groupUser?.groupId, user.id, {duration: '7d'}
              )
              .then =>
                @messageBatchesStreams.take(1).toPromise()
          }
      }
