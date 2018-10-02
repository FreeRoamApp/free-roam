z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
NewCampground = require '../../components/new_campground'

if window?
  require './index.styl'

module.exports = class NewCampgroundPage
  constructor: ({@model, requests, @router, overlay$, serverData}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newCampground = new NewCampground {@model, @router, overlay$}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newCampgroundPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-new-thread', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'newCampgroundPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$newCampground
