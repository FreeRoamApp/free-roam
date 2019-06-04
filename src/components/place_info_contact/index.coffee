z = require 'zorium'

Icon = require '../icon'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceInfoContact
  constructor: ({@model, @router, place}) ->
    @$locationIcon = new Icon()
    @$websiteIcon = new Icon()
    @$phoneIcon = new Icon()

    @state = z.state
      place: place

  render: =>
    {place} = @state.getValue()

    z '.z-place-info-contact',
      z '.block.location',
        z '.icon',
          z @$locationIcon,
            icon: 'location'
            isTouchTarget: false
            color: colors.$primary500

        z '.text',
          "#{place?.location?.lat}, #{place?.location?.lon}"

      if place?.contact?.phone
        matches = place.contact?.phone?.number.match(
          /^(\d{3})(\d{3})(\d{4})$/
        )
        phone = if matches
          "(#{matches[1]}) #{matches[2]}-#{matches[3]}"
        z '.block.phone',
          z '.icon',
            z @$phoneIcon,
              icon: 'phone'
              isTouchTarget: false
              color: colors.$primary500
          z '.text', phone
      if place?.contact?.website
        z '.block.website',
          z '.icon',
            z @$websiteIcon,
              icon: 'web'
              isTouchTarget: false
              color: colors.$primary500
          z '.text',
            @router.link z 'a', {
              href: place.contact?.website
            }, place.contact?.website
