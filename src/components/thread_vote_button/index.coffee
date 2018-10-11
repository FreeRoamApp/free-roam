z = require 'zorium'
colors = require '../../colors'

Icon = require '../icon'

module.exports = class ThreadVoteButton
  constructor: ({@model}) ->
    @$icon = new Icon()

    @state = z.state
      me: @model.user.getMe()

  render: (options) =>
    {parent, parentType, vote, hasVoted, hasRipple
      isTouchTarget, color, size, onclick} = options

    {me} = @state.getValue()

    color ?= colors.$bgText
    hasRipple ?= true
    size ?= '18px'

    z '.z-thread-vote-button',
      z @$icon,
        icon: "thumb-#{vote}"
        hasRipple: hasRipple
        size: size
        isTouchTarget: isTouchTarget
        color: if hasVoted \
               then colors.$primary500
               else color
        onclick: (e) =>
          e?.stopPropagation()
          e?.preventDefault()
          unless hasVoted
            onclick?()
            @model.user.requestLoginIfGuest me
            .then =>
              @model.threadVote.upsertByParent(
                parent
                {vote}
              )
