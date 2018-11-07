z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Item = require '../../components/item'
BasePage = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemPage extends BasePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @item = @clearOnUnmount requests.switchMap ({route}) =>
      @model.item.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$item = new Item {@model, @router, @item}

    @state = z.state
      item: @item

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
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      @$item
