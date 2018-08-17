z = require 'zorium'

NewThread = require '../../components/new_thread'

if window?
  require './index.styl'

module.exports = class NewThreadPage
  constructor: ({@model, requests, @router, serverData, group}) ->
    category = requests.map ({route}) ->
      route.params.category
    uuid = requests.map ({route}) ->
      route.params.uuid

    @$newThread = new NewThread {@model, @router, category, uuid, group}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newThreadPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-new-thread', {
      style:
        height: "#{windowSize.height}px"
    },
      @$newThread
