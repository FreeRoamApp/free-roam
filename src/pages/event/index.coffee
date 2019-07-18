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
    @$deleteIcon = new Icon()
    @$shareIcon = new Icon()
    @$event = new Event {@model, @router, @event}

    @state = z.state
      event: @event
      me: @model.user.getMe()

  getMeta: =>
    @event.map (event) ->
      {
        title: event?.name
        description: event?.details
      }

  render: =>
    {event, me} = @state.getValue()

    z '.p-event',
      z @$appBar, {
        title: @model.l.get 'general.meetup'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-event_top-right',
            if me?.username is 'austin'
              z @$deleteIcon,
                icon: 'delete'
                color: colors.$header500Icon
                hasRipple: true
                onclick: =>
                  if confirm 'Are you sure?'
                    @model.event.deleteByRow event
                    .then =>
                      @router.go 'social'

            z @$shareIcon,
              icon: 'share'
              color: colors.$header500Icon
              hasRipple: true
              onclick: =>
                ga? 'send', 'event', 'events', 'share'
                path = @router.get 'event', {
                  slug: event.slug
                }
                @model.portal.call 'share.any', {
                  text: event.name
                  path: path
                  url: "https://#{config.HOST}#{path}"
                }
      }
      @$event
