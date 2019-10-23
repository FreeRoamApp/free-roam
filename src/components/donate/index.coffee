z = require 'zorium'

DonateBox = require '../donate_box'

if window?
  require './index.styl'

module.exports = class Donate
  constructor: ({@model, @router}) ->
    @$donateBox = new DonateBox {@model, @router}

    # @state = z.state {}

  render: =>
    # {} = @state.getValue()

    # TODO: json file with vars that are used in stylus and js
    # eg $breakPointLarge
    isDesktop = window?.matchMedia('(min-width: 1280px)').matches

    z '.z-donate',
      if isDesktop
        z '.top',
          z '.box',
            z @$donateBox
          z '.art'
      z '.description',
        z '.content',
          z '.title', @model.l.get 'donate.descriptionTitle'
          z '.text', @model.l.get 'donate.descriptionText'

      if not isDesktop
        z '.top',
          z @$donateBox
      z '.tax-info',
        z '.content',
          @model.l.get 'donate.taxInfo'
