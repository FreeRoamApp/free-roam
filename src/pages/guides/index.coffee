z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
ProductGuides = require '../../components/product_guides'
HowToGuides = require '../../components/how_to_guides'
ProductGuidesOnboard = require '../../components/product_guides_onboard'
Tabs = require '../../components/tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GuidesPage
  @hasBottomBar: true

  constructor: ({@model, @router, requests, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$productGuides = new ProductGuides {@model, @router}
    @$howToGuides = new HowToGuides {@model, @router}

    isProductGuidesOnboardVisible = new RxBehaviorSubject(
      @model.experiment.get('guidesOnboard') is 'visible' and
        not @model.cookie.get 'hasSeenGuidesOnboard'
    )

    @$productGuidesOnboard = new ProductGuidesOnboard {
      @model, @router, isVisible: isProductGuidesOnboardVisible
    }

    @state = z.state {
      isProductGuidesOnboardVisible
    }

  getMeta: =>
    {
      title: @model.l.get 'guidesPage.title'
      # description: guides?.why
    }

  render: =>
    {isProductGuidesOnboardVisible} = @state.getValue()

    z '.p-guides',
      z @$appBar, {
        title: @model.l.get 'guidesPage.title'
        isFlat: true
        # isPrimary: true
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      z '.content',
        z @$tabs,
          isBarFixed: false
          # isPrimary: true
          tabs: [
            {
              $menuText: @model.l.get 'guidesPage.products'
              $el: @$productGuides
            }
            {
              $menuText: @model.l.get 'guidesPage.howTo'
              $el: z @$howToGuides
            }
          ]

        if isProductGuidesOnboardVisible
          z '.onboard',
            z @$productGuidesOnboard

      @$bottomBar
