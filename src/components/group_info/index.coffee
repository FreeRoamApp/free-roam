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

module.exports = class GroupInfo extends Base
  constructor: ({@model, @router, @group}) ->
    me = @model.user.getMe()

    @$datesIcon = new Icon()
    @$locationIcon = new Icon()
    @$priceIcon = new Icon()
    @$webIcon = new Icon()

    @$spinner = new Spinner()

    @$details = new FormattedText {
      text: @group.map (group) -> group?.details
      imageWidth: 'auto'
      isFullWidth: true
      embedVideos: false
      @model
      @router
    }

    @state = z.state {
      group: @group.map (group) ->
        _defaults {
          startTime: DateService.format new Date(group?.startTime), 'MMM D'
          endTime: DateService.format new Date(group?.endTime), 'MMM D'
        }, group
    }

  afterMount: =>
    super
    # FIXME: figure out why i can't use take(1) here...
    # returns null for some. probably has to do with the unloading we do in
    # pages/base
    @disposable = @group.subscribe (group) =>
      # if group?.attachmentsPreview?.count
      if group?.slug
        @fadeInWhenLoaded @getCoverUrl(group)

  getCoverUrl: (group) =>
    # @model.image.getSrcByPrefix(
    #   place.attachmentsPreview.first.prefix, {size: 'large'}
    # )
    "#{config.CDN_URL}/groups/#{_snakeCase(group.slug)}.jpg"

  render: =>
    {group} = @state.getValue()

    price = if group?.prices?.all is 0 \
            then 'Free'
            else if group?.prices?.all
            then "$#{group?.prices?.all}"
            else @model.l.get 'general.unknown'

    z '.z-group-info', {
      className: z.classKebab {@isImageLoaded}
    },
      if not group?.slug
        z @$spinner
      else [
        z '.cover', {
          style:
            backgroundImage:
              "url(#{@getCoverUrl(group)})"
        }
        z '.g-grid',
          z '.name', group?.name
          z '.info',
            z '.section.dates',
              z '.icon',
                z @$datesIcon,
                  icon: 'clock'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                "#{group?.startTime} - #{group?.endTime}"


            z '.section.location',
              z '.icon',
                z @$locationIcon,
                  icon: 'location'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                @model.placeBase.getLocation group


            z '.section.price',
              z '.icon',
                z @$priceIcon,
                  icon: 'usd'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                price


            @router.link z 'a.section.website', {
              href: group?.contact?.website
            },
              z '.icon',
                z @$webIcon,
                  icon: 'web'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text',
                group?.contact?.website

          z '.title', @model.l.get 'place.details'
          z '.details', @$details
      ]
