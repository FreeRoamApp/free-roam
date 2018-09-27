z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

Icon = require '../icon'
ActionBar = require '../action_bar'
MarkdownEditor = require '../markdown_editor'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Compose
  constructor: (options) ->
    {@model, @router, @titleValueStreams, overlay$,
      @bodyValueStreams, @attachmentsValueStreams, uploadFn} = options
    me = @model.user.getMe()

    @$actionBar = new ActionBar {@model}

    @attachmentsValueStreams ?= new RxReplaySubject 1
    @$markdownEditor = new MarkdownEditor {
      @model
      uploadFn
      overlay$
      valueStreams: @bodyValueStreams
      attachmentsValueStreams: @attachmentsValueStreams
    }

    @state = z.state
      me: me
      isLoading: false
      titleValue: @titleValueStreams.switch()

  setTitle: (e) =>
    @titleValueStreams.next RxObservable.of e.target.value

  setBody: (e) =>
    @bodyValueStreams.next RxObservable.of e.target.value

  beforeUnmount: =>
    @attachmentsValueStreams.next new RxBehaviorSubject []

  render: ({imagesAllowed, onDone, $head}) =>
    {me, isLoading, titleValue} = @state.getValue()

    z '.z-compose',
      z @$actionBar, {
        isSaving: isLoading
        cancel:
          text: @model.l.get 'general.discard'
          onclick: =>
            @router.back()
        save:
          text: @model.l.get 'general.done'
          onclick: (e) =>
            unless isLoading
              @state.set isLoading: true
              onDone e
              .catch -> null
              .then =>
                @state.set isLoading: false
      }
      z '.g-grid',
        $head

        z 'input.title',
          type: 'text'
          onkeyup: @setTitle
          onchange: @setTitle
          # bug where cursor goes to end w/ just value
          defaultValue: titleValue or ''
          placeholder: @model.l.get 'compose.titleHintText'

        z '.divider'

        z @$markdownEditor,
          imagesAllowed: imagesAllowed
          hintText: @model.l.get 'compose.postHintText'
