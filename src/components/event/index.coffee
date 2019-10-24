z = require 'zorium'
_defaults = require 'lodash/defaults'
_snakeCase = require 'lodash/snakeCase'

Base = require '../base'
Icon = require '../icon'
Spinner = require '../spinner'
FormattedText = require '../formatted_text'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Event extends Base
  constructor: ({@model, @router, @event}) ->
    me = @model.user.getMe()

    @$datesIcon = new Icon()
    @$locationIcon = new Icon()
    @$priceIcon = new Icon()
    @$webIcon = new Icon()

    @$spinner = new Spinner()

    @$details = new FormattedText {
      text: @event.map (event) -> event?.details
      imageWidth: 'auto'
      isFullWidth: true
      embedVideos: false
      @model
      @router
    }

    @state = z.state {
      event: @event.map (event) ->
        _defaults {
          startTime: DateService.format new Date(event?.startTime), 'MMM D'
          endTime: DateService.format new Date(event?.endTime), 'MMM D'
        }, event
    }

  afterMount: =>
    super
    # FIXME: figure out why i can't use take(1) here...
    # returns null for some. probably has to do with the unloading we do in
    # pages/base
    @disposable = @event.subscribe (event) =>
      # if event?.attachmentsPreview?.count
      if event?.slug
        @fadeInWhenLoaded @getCoverUrl(event)

  getCoverUrl: (event) =>
    # @model.image.getSrcByPrefix(
    #   place.attachmentsPreview.first.prefix, {size: 'large'}
    # )
    "#{config.CDN_URL}/events/#{_snakeCase(event.slug)}.jpg"

  render: =>
    {event} = @state.getValue()

    price = if event?.prices?.all is 0 \
            then 'Free'
            else if event?.prices?.all
            then "$#{event?.prices?.all}"
            else @model.l.get 'general.unknown'

    z '.z-event', {
      className: z.classKebab {@isImageLoaded}
    },
      if not event?.slug
        z @$spinner
      else [
        z '.cover', {
          style:
            backgroundImage:
              "url(#{@getCoverUrl(event)})"
        }
        z '.g-grid',
          z '.name', event?.name
          z '.info',
            z '.section.dates',
              z '.icon',
                z @$datesIcon,
                  icon: 'clock'
                  isTouchTarget: false
                  color: colors.$primaryMain
              z '.text',
                "#{event?.startTime} - #{event?.endTime}"


            z '.section.location',
              z '.icon',
                z @$locationIcon,
                  icon: 'location'
                  isTouchTarget: false
                  color: colors.$primaryMain
              z '.text',
                @model.placeBase.getLocation event


            z '.section.price',
              z '.icon',
                z @$priceIcon,
                  icon: 'usd'
                  isTouchTarget: false
                  color: colors.$primaryMain
              z '.text',
                price


            @router.link z 'a.section.website', {
              href: event?.contact?.website
            },
              z '.icon',
                z @$webIcon,
                  icon: 'web'
                  isTouchTarget: false
                  color: colors.$primaryMain
              z '.text',
                event?.contact?.website

          z '.title', @model.l.get 'place.details'
          z '.details', @$details
      ]
