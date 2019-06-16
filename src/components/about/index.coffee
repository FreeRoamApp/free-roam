z = require 'zorium'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
TertiaryButton = require '../tertiary_button'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class About
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @$learnMoreButton = new TertiaryButton()

    @$shareButton = new PrimaryButton()
    @$reviewButton = new PrimaryButton()
    @$feedbackButton = new PrimaryButton()

    @$irsButton = new SecondaryButton()

    @state = z.state
      windowSize: @model.window.getSize()

  render: =>
    {windowSize} = @state.getValue()

    z '.z-about',
      z '.g-grid',
        z '.mission',
          z 'h1.title', @model.l.get 'about.missionTitle'
          z '.text', @model.l.get 'about.mission'
          # z '.button',
          #   z @$learnMoreButton,
          #     text: @model.l.get 'general.learnMore'
          #     isOutline: true

        z '.meet',
          z 'h1.title', @model.l.get 'about.meetTitle'
          z '.g-grid',
            z '.g-cols',
              z '.g-col.g-xs-12.g-md-6',
                z '.image.austin'
                z '.name', 'Austin'
                z '.text',
                  @model.l.get 'about.meetAustinText'
              z '.g-col.g-xs-12.g-md-6',
                z '.image.rachel'
                z '.name', 'Rachel'
                z '.text',
                  @model.l.get 'about.meetRachelText'

        z '.help',
          z 'h1.title', @model.l.get 'about.helpTitle'
          z '.text', @model.l.get 'about.help'
          z '.g-grid',
            z '.g-cols',
              z '.g-col.g-xs-12.g-md-4',
                z '.image.share'
                z '.title', @model.l.get 'about.helpShareTitle'
                z '.description', @model.l.get 'about.helpShare'
                z '.button',
                  z @$shareButton,
                    text: @model.l.get 'about.helpShareButton'
                    onclick: =>
                      null
                    colors:
                      c200: colors.$green200
                      c500: colors.$green500
                      c600: colors.$green600
                      c700: colors.$green700
                      ink: colors.$white
              z '.g-col.g-xs-12.g-md-4',
                z '.image.review'
                z '.title', @model.l.get 'about.helpReviewTitle'
                z '.description', @model.l.get 'about.helpReview'
                z '.button',
                  z @$reviewButton,
                    text: @model.l.get 'about.helpReviewButton'
                    onclick: =>
                      null
                    colors:
                      c200: colors.$blue200
                      c500: colors.$blue500
                      c600: colors.$blue600
                      c700: colors.$blue700
                      ink: colors.$white
              z '.g-col.g-xs-12.g-md-4',
                z '.image.feedback'
                z '.title', @model.l.get 'about.helpFeedbackTitle'
                z '.description', @model.l.get 'about.helpFeedback'
                z '.button',
                  z @$feedbackButton,
                    text: @model.l.get 'about.helpFeedbackButton'
                    onclick: =>
                      null
                    colors:
                      c200: colors.$yellow200
                      c500: colors.$yellow500
                      c600: colors.$yellow600
                      c700: colors.$yellow700
                      ink: colors.$white

        z '.transparency',
          z 'h1.title', @model.l.get 'about.transparencyTitle'
          z '.text',
            @model.l.get 'about.transparency1'
            @router.link z 'a', {
              href: 'http://github.com/freeroamapp'
            }, @model.l.get 'general.here'
            ' '
            @model.l.get 'about.transparency2'

          z '.button',
            z @$irsButton,
              text: @model.l.get 'about.irsDetermination'
              isOutline: true
              isFullWidth: false
              onclick: =>
                @router.openLink(
                  'https://fdn.uno/d/documents/irs-determination.pdf'
                )

        # z 'p.disclaimer', @model.l.get 'about.amazon'
        z '.disclaimer', @model.l.get 'about.opencellid'
