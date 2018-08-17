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
              @model.conversationMessage.deleteByUuid id
              .then =>
                @messageBatchesStreams.take(1).toPromise()
            onDeleteMessagesLast7d: =>
              @model.conversationMessage.deleteAllByGroupUuidAndUserUuid(
                groupUser?.groupUuid, user.uuid, {duration: '7d'}
              )
              .then =>
                @messageBatchesStreams.take(1).toPromise()
          }, user
      }
