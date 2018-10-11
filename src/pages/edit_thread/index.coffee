z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/switchMap'

NewThread = require '../../components/new_thread'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditThreadPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, group}) ->
    thread = requests.switchMap ({route}) =>
      if route.params.slug
        @model.thread.getBySlug route.params.slug
      else
        RxObservable.of null

    @$editThread = new NewThread {
      @model
      @router
      thread
      group
    }

    @state = z.state
      windowSize: @model.window.getSize()
      thread: thread

  getMeta: =>
    {
      title: @model.l.get 'editThreadPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-edit-thread', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$editThread
