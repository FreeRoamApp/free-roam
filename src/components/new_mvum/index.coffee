z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_filter = require 'lodash/filter'
_map = require 'lodash/map'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
Dropdown = require '../dropdown'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewMvum
  constructor: ({@model, @router, center}) ->
    me = @model.user.getMe()

    @nameValue = new RxBehaviorSubject ''
    @nameError = new RxBehaviorSubject null
    @$nameInput = new PrimaryInput
      value: @nameValue
      error: @nameError

    @urlValue = new RxBehaviorSubject ''
    @urlError = new RxBehaviorSubject null
    @$urlInput = new PrimaryInput
      value: @urlValue
      error: @urlError

    @regionValue = new RxBehaviorSubject ''
    @$regionDropdown = new Dropdown {
      value: @regionValue
    }

    @$saveButton = new PrimaryButton()

    @state = z.state {
      isLoading: false
      lastSavedName: null
      requestRegion: false
      regions: @model.region.getAllByAgencySlug 'usfs'
    }

  upsert: (e) =>
    {isLoading} = @state.getValue()
    unless isLoading
      @state.set isLoading: true, lastSavedName: null
      @nameError.next null
      @urlError.next null

      @model.localMap.upsert {
        type: 'mvum'
        name: @nameValue.getValue()
        url: @urlValue.getValue()
        regionSlug: @regionValue.getValue()
      }
      .then =>
        @state.set {
          isLoading: false, lastSavedName: @nameValue.getValue()
          requestRegion: false
        }
        @nameValue.next ''
        @urlValue.next ''
        alert @model.l.get 'general.saved'
        # @regionValue.next ''
      .catch (err) =>
        err = try
          JSON.parse err.message
        catch
          {}
        console.log err
        errorSubject = switch err.info?.field
          when 'name' then @nameError
          else @urlError
        errorSubject.next err.info?.message or 'Error'

        if err.info?.requestRegion
          @state.set requestRegion: true

        @state.set isLoading: false
        alert 'Error'

  render: =>
    {isLoading, lastSavedName, requestRegion, regions} = @state.getValue()

    z '.z-new-mvum',
      z '.g-grid',
        if lastSavedName
          z '.saved', "#{@model.l.get 'general.saved'} #{lastSavedName}"
        z '.notes',
          @model.l.get 'newMvum.notes'
        z 'label.field',
          z '.name', @model.l.get 'newMvum.name'
          z @$nameInput,
            hintText: @model.l.get 'newMvum.name'

        z 'label.field',
          z '.name', @model.l.get 'newMvum.url'
          z @$urlInput,
            hintText: @model.l.get 'newMvum.url'

        z 'label.field',
          z @$regionDropdown,
            options: [
              {
                value: ''
                text: 'Guess from map'
              }
            ].concat _map regions, (region) ->
              {
                value: region.slug
                text: region.name
              }

        z '.actions',
          z @$saveButton,
            text: if isLoading \
                  then @model.l.get 'general.loading'
                  else @model.l.get 'general.save'
            onclick: @upsert
