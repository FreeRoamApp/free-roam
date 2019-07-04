z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
EventList = require '../../components/event_list'
Icon = require '../../components/icon'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EventsPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$shareIcon = new Icon()
    @$eventList = new EventList {
      @model, @router
      events: @model.event.getAll()
    }

  getMeta: ->
    {
      title: 'Events'
    }

  render: =>
    z '.p-events',
      z @$appBar, {
        title: @model.l.get 'general.events'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          z '.share',
            z @$shareIcon,
              icon: 'share'
              color: colors.$header500Icon
              hasRipple: true
              onclick: =>
                ga? 'send', 'event', 'events', 'share'
                path = @router.get 'events'
                @model.portal.call 'share.any', {
                  text: 'Vanlife & RV Meetups'
                  path: path
                  url: "https://#{config.HOST}#{path}"
                }
      }
      z '.events',
        @$eventList
