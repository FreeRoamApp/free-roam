z = require 'zorium'
_map = require 'lodash/map'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Items = require '../../components/items'
Base = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class ItemsPage extends Base
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    filter = @clearOnUnmount requests.map ({route}) ->
      if route.params.category
        {type: 'category', value: route.params.category}
      else if route.params.query
        {type: 'search', value: route.params.query}
      else
        {}

    filterInfo = filter.switchMap (filter) =>
      if filter?.type is 'category'
        @model.category.getAll()
        .map (categories) =>
          _find(categories, {slug: filter.value})
      else if filter
        RxObservable.of {name: filter.value}
      else
        RxObservable.of null

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$items = new Items {@model, @router, filter, filterInfo}

    @title = filterInfo.map (filterInfo) =>
      filterInfo?.name

    @state = z.state
      title: @title

  getMeta: =>
    @title.map (title) =>
      {
        title: title
        description: @model.l.get 'itemsPage.description', {
          replacements: {title}
        }
      }

  render: =>
    {title} = @state.getValue()

    z '.p-items',
      z @$appBar, {
        title: title
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primary500Text}
      }
      @$items
