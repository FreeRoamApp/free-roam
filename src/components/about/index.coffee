z = require 'zorium'

Icon = require '../icon'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
TertiaryButton = require '../tertiary_button'
Tabs = require '../tabs'
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

    @$tabs = new Tabs {@model, @selectedIndex}

    @state = z.state
      windowSize: @model.window.getSize()

  render: =>
    {windowSize} = @state.getValue()

    z '.z-about',
      z '.mission',
        z '.g-grid',
          z 'h1.title', @model.l.get 'about.missionTitle'
          z '.text', @model.l.get 'about.mission'
          z '.button',
            z @$learnMoreButton,
              text: @model.l.get 'drawer.roamWithCare'
              isOutline: true
              onclick: =>
                @router.go 'roamWithCare'

      z '.roadmap',
        z '.info',
          z '.title', @model.l.get 'about.roadmapTitle'
          z '.description', @model.l.get 'about.roadmapDescription'
        z @$tabs,
          isBarFixed: false
          isBarArrow: true
          tabs: [
            {
              $menuText: @model.l.get 'about.phase1'
              $el:
                z '.z-about_roadmap-phase.phase-1',
                  z '.image'
                  z '.phase', @model.l.get('about.phase1')+ ':'
                  z '.title', @model.l.get 'about.phase1Title'
                  z 'ul.bullets',
                    z 'li', @model.l.get 'about.phase1Bullet1'
                    z 'li', @model.l.get 'about.phase1Bullet2'
                    z 'li', @model.l.get 'about.phase1Bullet3'
            }
            {
              $menuText: @model.l.get 'about.phase2'
              $el:
                z '.z-about_roadmap-phase.phase-2',
                  z '.image'
                  z '.phase', @model.l.get('about.phase2')+ ':'
                  z '.title', @model.l.get 'about.phase2Title'
                  z 'ul.bullets',
                    z 'li', @model.l.get 'about.phase2Bullet1'
                    z 'li', @model.l.get 'about.phase2Bullet2'
                    # z 'li', @model.l.get 'about.phase2Bullet3'
            }
            {
              $menuText: @model.l.get 'about.phase3'
              $el:
                z '.z-about_roadmap-phase.phase-3',
                  z '.image'
                  z '.phase', @model.l.get('about.phase3')+ ':'
                  z '.title', @model.l.get 'about.phase3Title'
                  z 'ul.bullets',
                    z 'li', @model.l.get 'about.phase3Bullet1'
                    z 'li', @model.l.get 'about.phase3Bullet2'
                    z 'li', @model.l.get 'about.phase3Bullet3'
            }
            {
              $menuText: @model.l.get 'about.phase4'
              $el:
                z '.z-about_roadmap-phase.phase-4',
                  z '.image'
                  z '.phase', @model.l.get('about.phase4')+ ':'
                  z '.title', @model.l.get 'about.phase4Title'
                  z 'ul.bullets',
                    z 'li', @model.l.get 'about.phase4Bullet1'
                    # z 'li', @model.l.get 'about.phase4Bullet2'
                    # z 'li', @model.l.get 'about.phase4Bullet3'
            }
          ]

      z '.meet',
        z '.g-grid',
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
        z '.g-grid',
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
                      @model.portal.call 'share.any', {
                        text: 'FreeRoam'
                        path: ''
                        url: "https://#{config.HOST}"
                      }
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
                      @router.go 'home'
                    colors:
                      c200: colors.$skyBlue200
                      c500: colors.$skyBlue500
                      c600: colors.$skyBlue600
                      c700: colors.$skyBlue700
                      ink: colors.$white
              z '.g-col.g-xs-12.g-md-4',
                z '.image.feedback'
                z '.title', @model.l.get 'about.helpFeedbackTitle'
                z '.description', @model.l.get 'about.helpFeedback'
                z '.button',
                  z @$feedbackButton,
                    text: @model.l.get 'about.helpFeedbackButton'
                    onclick: =>
                      @router.go 'groupChat', {
                        groupId: 'boondocking'
                      }
                    colors:
                      c200: colors.$yellow200
                      c500: colors.$yellow500
                      c600: colors.$yellow600
                      c700: colors.$yellow700
                      ink: colors.$white

      z '.transparency',
        z '.g-grid',
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
              # isFullWidth: false
              onclick: =>
                @router.openLink(
                  'https://fdn.uno/d/documents/irs-determination.pdf'
                )

      # z 'p.disclaimer', @model.l.get 'about.amazon'
      z '.disclaimer',
        z '.g-grid',
          @model.l.get 'about.opencellid'
