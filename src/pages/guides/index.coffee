z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
ProductGuides = require '../../components/product_guides'
HowToGuides = require '../../components/how_to_guides'
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

  getMeta: =>
    {
      title: @model.l.get 'guidesPage.title'
      # description: guides?.why
    }

  render: =>
    z '.p-guides',
      z @$appBar, {
        title: @model.l.get 'guidesPage.title'
        isFlat: true
        # isPrimary: true
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
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
      @$guides

      @$bottomBar
