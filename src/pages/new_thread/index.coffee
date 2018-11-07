z = require 'zorium'

NewThread = require '../../components/new_thread'

if window?
  require './index.styl'

module.exports = class NewThreadPage
  constructor: ({@model, requests, @router, serverData, group}) ->
    category = requests.map ({route}) ->
      route.params.category
    id = requests.map ({route}) ->
      route.params.id

    @$newThread = new NewThread {@model, @router, category, id, group}

  getMeta: =>
    {
      title: @model.l.get 'newThreadPage.title'
    }

  render: =>
    z '.p-new-thread',
      @$newThread
