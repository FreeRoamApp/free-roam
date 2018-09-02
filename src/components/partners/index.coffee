z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Partners
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-partners',
      z '.g-grid',
        z 'p', @model.l.get 'partners.text1'
        z 'h2.subhead', @model.l.get 'partners.howItWorks'
        z 'p', @model.l.get 'partners.text2'
          # 'For anyone who isn\'t aware, Amazon has an affiliate program that lets members earn ~5% commission
          # on sales purchased through that user\'s link. The buyer pays the same amount, so the money comes
          # out of what Amazon would normal earn per sale.'
        z 'p', @model.l.get 'partners.text3'
        z 'p', @model.l.get 'partners.text4'
        z 'ul.requirements',
          z 'li.requirement', @model.l.get 'partners.requirement1'
          z 'li.requirement', @model.l.get 'partners.requirement2'
        z 'p', @model.l.get 'partners.text5'
