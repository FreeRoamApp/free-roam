z = require 'zorium'
_find = require 'lodash/find'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Conversation = require '../../components/conversation'
ProfileDialog = require '../../components/profile_dialog'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ConversationPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    conversation = requests.switchMap ({route}) =>
      @model.conversation.getById route.params.id
    .publishReplay(1).refCount()

    selectedProfileDialogUser = new RxBehaviorSubject null

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$profileDialog = new ProfileDialog {
      @model, @router, selectedProfileDialogUser
    }
    @$conversation = new Conversation {
      @model, @router, conversation, selectedProfileDialogUser, group
    }

    @state = z.state
      me: @model.user.getMe()
      conversation: conversation
      selectedProfileDialogUser: selectedProfileDialogUser

  getMeta: =>
    {
      title: @model.l.get 'general.chat'
    }

  render: =>
    {conversation, me, selectedProfileDialogUser} = @state.getValue()

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

      if selectedProfileDialogUser
        z @$profileDialog, {user: selectedProfileDialogUser}
