z = require 'zorium'
_defaults = require 'lodash/defaults'

Message = require '../message'

if window?
  require './index.styl'

module.exports = class ConversationMessage
  constructor: (options) ->
    {@selectedProfileDialogUser, @messageBatchesStreams, @model,
      @isTextareaFocused} = options
    @$message = new Message options

  render:  =>
    z '.z-conversation-message',
      z @$message, {
        openProfileDialogFn: (id, user, groupUser) =>
          @selectedProfileDialogUser.next _defaults {
            groupUser: groupUser
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
          }, user
      }
