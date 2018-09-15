z = require 'zorium'

NewThread = require '../../components/new_thread'

if window?
  require './index.styl'

module.exports = class NewThreadPage
  constructor: ({@model, requests, @router, overlay$, serverData, group}) ->
    category = requests.map ({route}) ->
      route.params.category
    id = requests.map ({route}) ->
      route.params.id

    @$newThread = new NewThread {@model, @router, overlay$, category, id, group}

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
