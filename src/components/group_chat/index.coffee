z = require 'zorium'
_defaults = require 'lodash/defaults'

Conversation = require '../conversation'

if window?
  require './index.styl'

module.exports = class GroupChat
  constructor: (options) ->
    {@model, @router, @conversation, overlay$, group, isLoading, onScrollUp
      minUuid, onScrollDown, hasBottomBar,
      selectedProfileDialogUser} = options

    @$conversation = new Conversation {
      @model
      @router
      selectedProfileDialogUser
      @conversation
      group
      overlay$
      minUuid
      onScrollUp
      onScrollDown
      hasBottomBar
      isLoading: isLoading
      isGroup: true
    }

    @state = z.state {
      group
      @conversation
    }

  render: =>
    {group, conversation} = @state.getValue()

    z '.z-group-chat',
      z @$conversation
