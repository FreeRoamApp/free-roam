z = require 'zorium'
_defaults = require 'lodash/defaults'

Conversation = require '../conversation'

if window?
  require './index.styl'

module.exports = class GroupChat
  constructor: (options) ->
    {@model, @router, @conversation, group, isLoading, onScrollUp
      minId, onScrollDown, hasBottomBar} = options

    @$conversation = new Conversation {
      @model
      @router
      @conversation
      group
      minId
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
