z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'

if window?
  require './index.styl'

module.exports = class EditPlacePage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData, parent}) ->
    place = requests.switchMap ({route}) =>
      console.log 'place', route.params.slug
      @placeModel.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$editPlace = new @EditPlace {@model, @router, place}

  getMeta: =>
    {
      title: @model.l.get 'editPlacePage.title'
    }

  render: =>
    z '.p-edit-place-review',
      z @$appBar, {
        title: @model.l.get 'editPlacePage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
      }
      @$editPlace
