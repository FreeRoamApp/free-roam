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

  getMeta: =>
    {
      title: @model.l.get 'editThreadPage.title'
    }

  render: =>
    z '.p-edit-thread',
      z @$editThread
