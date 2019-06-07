z = require 'zorium'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Conversation = require '../../components/conversation'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ConversationPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    conversation = requests.switchMap ({route}) =>
      @model.conversation.getById route.params.id
    .publishReplay(1).refCount()

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$conversation = new Conversation {
      @model, @router, conversation, group
    }

    @state = z.state
      me: @model.user.getMe()
      conversation: conversation

  getMeta: =>
    {
      title: @model.l.get 'general.chat'
    }

  render: =>
    {conversation, me} = @state.getValue()

    toUser = _find conversation?.users, (user) ->
      me?.id isnt user.id

    z '.p-conversation',
      z @$appBar, {
        title: @model.user.getDisplayName toUser
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        isFullWidth: true
      }
      z '.g-grid',
        @$conversation
