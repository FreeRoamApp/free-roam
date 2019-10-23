z = require 'zorium'

PrimaryButton = require '../primary_button'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Preservation
  constructor: ({@model, @router}) ->
    @$packOutButton = new PrimaryButton()
    @$fireSafetyButton = new PrimaryButton()
    @$trailsButton = new PrimaryButton()
    @$rulesButton = new PrimaryButton()

    # @state = z.state {}

  render: =>
    # {} = @state.getValue()

    z '.z-preservation',
      z '.top',
        z '.g-grid',
          z 'h1.title', @model.l.get 'preservation.title'
          z '.description', @model.l.get 'preservation.description'
      z '.content',
        z '.lesson',
          z '.g-grid',
            z '.icon.pack-out'
            z '.title', @model.l.get 'preservation.packOutTitle'
            z '.description', @model.l.get 'preservation.packOut'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.packOutBullet1'
              z 'li', @model.l.get 'preservation.packOutBullet2'
              z 'li', @model.l.get 'preservation.packOutBullet3'
              z 'li', @model.l.get 'preservation.packOutBullet4'
              z 'li', @model.l.get 'preservation.packOutBullet5'
            z '.button',
              z @$packOutButton,
                text: @model.l.get 'general.learnMore'
                colors:
                  c200: colors.$red500
                  c500: colors.$red500
                  c600: colors.$red400
                  c700: colors.$red400
                  ink: colors.$red500Text
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://lnt.org/why/7-principles/dispose-of-waste-properly/'
                    target: '_system'
                  }
        z '.lesson',
          z '.g-grid',
            z '.icon.fire-safety'
            z '.title', @model.l.get 'preservation.fireSafetyTitle'
            z '.description', @model.l.get 'preservation.fireSafety'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.fireSafetyBullet1'
              z 'li', @model.l.get 'preservation.fireSafetyBullet2'
              z 'li', @model.l.get 'preservation.fireSafetyBullet3'
            z '.button',
              z @$fireSafetyButton,
                text: @model.l.get 'general.learnMore'
                colors:
                  c200: colors.$orange500
                  c500: colors.$orange500
                  c600: colors.$orange400
                  c700: colors.$orange400
                  ink: colors.$white
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://lnt.org/why/7-principles/minimize-campfire-impacts/'
                    target: '_system'
                  }
        z '.lesson',
          z '.g-grid',
            z '.icon.trails'
            z '.title', @model.l.get 'preservation.trailsTitle'
            z '.description', @model.l.get 'preservation.trails'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.trailsBullet1'
            z '.button',
              z @$trailsButton,
                text: @model.l.get 'general.learnMore'
                colors:
                  c200: colors.$green500
                  c500: colors.$green500
                  c600: colors.$green400
                  c700: colors.$green400
                  ink: colors.$green500Text
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://lnt.org/why/7-principles/travel-camp-on-durable-surfaces/'
                    target: '_system'
                  }
        z '.lesson',
          z '.g-grid',
            z '.icon.rules'
            z '.title', @model.l.get 'preservation.rulesTitle'
            z '.description', @model.l.get 'preservation.rules'
            z 'ul.bullets',
              z 'li', @model.l.get 'preservation.rulesBullet1'
              z 'li', @model.l.get 'preservation.rulesBullet2'
            z '.button',
              z @$rulesButton,
                text: @model.l.get 'general.learnMore'
                colors:
                  c200: colors.$skyBlue500
                  c500: colors.$skyBlue500
                  c600: colors.$skyBlue400
                  c700: colors.$skyBlue400
                  ink: colors.$white
                onclick: =>
                  @model.portal.call 'browser.openWindow', {
                    url: 'https://www.fs.usda.gov/detailfull/fishlake/recreation/?cid=stelprdb5121831'
                    target: '_system'
                  }
