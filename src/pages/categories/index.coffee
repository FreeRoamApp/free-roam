z = require 'zorium'
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
Categories = require '../../components/categories'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CategoriesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$categories = new Categories {@model, @router}

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: ->
    {
      title: 'The best products for Boondocking'
    }

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-categories', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'categoriesPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
      }
      @$categories
      @$bottomBar
