z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Event = require '../../components/event'
Icon = require '../../components/icon'
BasePage = require '../base'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EventPage extends BasePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @event = @clearOnUnmount requests.switchMap ({route}) =>
      @model.event.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$shareIcon = new Icon()
    @$event = new Event {@model, @router, @event}

    @state = z.state
      event: @event

  getMeta: =>
    @event.map (event) ->
      {
        title: event?.name
        description: event?.details
      }

  render: =>
    {event} = @state.getValue()

    z '.p-event',
      z @$appBar, {
        title: @model.l.get 'general.meetup'
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
                path = @router.get 'event', {
                  slug: event?.slug
                }
                @model.portal.call 'share.any', {
                  text: 'Vanlife & RV Meetups'
                  path: path
                  url: "https://#{config.HOST}#{path}"
                }
      }
      @$event
