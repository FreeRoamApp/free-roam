z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
ItemProducts = require '../../components/item_products'
ItemGuide = require '../../components/item_guide'
ItemVideos = require '../../components/item_videos'
TooltipPositioner = require '../../components/tooltip_positioner'
BasePage = require '../base'
Tabs = require '../../components/tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemPage extends BasePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @item = @clearOnUnmount requests.switchMap ({route}) =>
      @model.item.getBySlug route.params.slug

    @selectedIndex = new RxBehaviorSubject 0

    @$appBar = new AppBar {@model}
    @$tabs = new Tabs {@model, @selectedIndex}
    @$buttonBack = new ButtonBack {@model, @router}
    @$itemProducts = new ItemProducts {@model, @router, @item}
    @$itemGuide = new ItemGuide {@model, @router, @item}
    @$itemVideos = new ItemVideos {@model, @router, @item}
    @$tooltip = new TooltipPositioner {
      @model
      key: 'itemGuides'
      anchor: 'top-center'
      offset:
        top: 12
    }

    @state = z.state
      item: @item

  afterMount: =>
    @disposable = @selectedIndex.subscribe (index) =>
      ga? 'send', 'event', 'social', 'tab', index
      if index is 1
        @$tooltip.close()

  getMeta: =>
    @item.map (item) =>
      {
        title: @model.l.get 'itemPage.title', {replacements: {name: item?.name}}
        description: item?.why
      }

  render: =>
    {item} = @state.getValue()

    z '.p-item',
      z @$appBar, {
        title: item?.name
        isFlat: true
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primaryMainText}
      }
      z @$tabs,
        isBarFixed: false
        isPrimary: true
        tabs: [
          {
            $menuText: @model.l.get 'itemsPage.products'
            $el: @$itemProducts
          }
          {
            $menuText: @model.l.get 'itemsPage.guide'
            $after:
              z '.p-item_tab-guide-icon',
                z @$tooltip
            $el: z @$itemGuide
          }
          {
            $menuText: @model.l.get 'itemsPage.videos'
            $el: z @$itemVideos
          }
        ]
      @$item
