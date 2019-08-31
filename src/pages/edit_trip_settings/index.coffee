z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

EditTripSettings = require '../../components/edit_trip_settings'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripSettingsPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    @$editTripSettings = new EditTripSettings {@model, @router, trip}

  getMeta: =>
    {
      title: @model.l.get 'editTripSettingsPage.title'
    }

  render: =>
    z '.p-edit-trip-settings',
      @$editTripSettings
