z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/map'
require 'rxjs/add/operator/switch'

Icon = require '../icon'
FlatButton = require '../flat_button'
PrimaryButton = require '../primary_button'
PrimaryInput = require '../primary_input'
PrimaryTextarea = require '../primary_textarea'
Toggle = require '../toggle'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupEditChannel
  constructor: ({@model, @router, group, conversation}) ->
    me = @model.user.getMe()

    @nameValueStreams = new RxReplaySubject 1
    @nameValueStreams.next (conversation?.map (conversation) ->
      conversation.data?.name) or RxObservable.of ''
    @nameError = new RxBehaviorSubject null

    @descriptionValueStreams = new RxReplaySubject 1
    @descriptionValueStreams.next (conversation?.map (conversation) ->
      conversation.data?.description) or RxObservable.of ''
    @descriptionError = new RxBehaviorSubject null

    @$nameInput = new PrimaryInput
      valueStreams: @nameValueStreams
      error: @nameError

    @$descriptionTextarea = new PrimaryTextarea
      valueStreams: @descriptionValueStreams
      error: @descriptionError

    if conversation
      groupAndConversation = RxObservable.combineLatest(
        group, conversation, (vals...) -> vals
      )

      @isWelcomeChannelStreams = new RxReplaySubject 1
      @isWelcomeChannelStreams.next (
        groupAndConversation?.map ([group, conversation]) ->
          group?.data?.welcomeChannelId is conversation?.id
        ) or RxObservable.of null
      @$isWelcomeChannelToggle = new Toggle {isSelectedStreams: @isWelcomeChannelStreams}

    @$cancelButton = new FlatButton()
    @$saveButton = new PrimaryButton()

    @state = z.state
      me: me
      isSaving: false
      group: group
      conversation: conversation
      name: @nameValueStreams.switch()
      description: @descriptionValueStreams.switch()
      isWelcomeChannel: @isWelcomeChannelStreams?.switch()

  save: (isNewChannel) =>
    {me, isSaving, group, conversation, name, description,
      isWelcomeChannel} = @state.getValue()

    if isSaving
      return

    @state.set isSaving: true
    @nameError.next null

    fn = (diff) =>
      if isNewChannel
        @model.conversation.create diff
      else
        @model.conversation.updateById conversation.id, diff

    fn {
      name
      description
      isWelcomeChannel
      groupId: group.id
    }
    .catch -> null
    .then (newConversation) =>
      conversation or= newConversation
      @state.set isSaving: false
      @model.group.goPath group, 'groupAdminManageChannels', {@router}

  render: ({isNewChannel} = {}) =>
    {me, isSaving, group, name, description} = @state.getValue()

    z '.z-group-edit-channel',
      z '.g-grid',
        z '.input',
          z @$nameInput,
            hintText: @model.l.get 'groupEditChannel.nameInputHintText'

        z '.input',
          z @$descriptionTextarea,
            hintText: @model.l.get 'general.description'

        if @$isWelcomeChannelToggle
          z '.input',
            z 'label.label',
              z '.text', @model.l.get 'groupEditChannel.welcomeChannel'
              @$isWelcomeChannelToggle

        z '.actions',
          z '.cancel-button',
            z @$cancelButton,
              isFullWidth: false
              text: @model.l.get 'general.cancel'
              onclick: =>
                @router.back()
          z '.save-button',
            z @$saveButton,
              isFullWidth: false
              text: if isSaving \
                    then @model.l.get 'general.loading'
                    else if isNewChannel
                    then @model.l.get 'general.create'
                    else @model.l.get 'general.save'
              onclick: =>
                @save isNewChannel
