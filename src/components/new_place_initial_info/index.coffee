z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_uniq = require 'lodash/uniq'

PrimaryInput = require '../primary_input'
PrimaryButton = require '../primary_button'
SecondaryButton = require '../secondary_button'
Dropdown = require '../dropdown'
Textarea = require '../textarea'
CoordinatePickerOverlay = require '../coordinate_picker_overlay'
Icon = require '../icon'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class NewPlaceInitialInfo
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$nameInput = new PrimaryInput
      valueStreams: @fields.name.valueStreams
      error: @fields.name.errorSubject

    @$locationInput = new PrimaryInput
      valueStreams: @fields.location.valueStreams
      error: @fields.location.errorSubject

    @$detailsTextarea = new Textarea {
      # need space for the long placeholder. 40000 sq px
      defaultHeight: Math.floor 40000 / @model.window.getSizeVal()?.width
      valueStreams: @fields.details.valueStreams
    }

    if @fields.subType and not @fields.agency
      @$subTypeDropdown = new Dropdown {
        valueStreams: @fields.subType.valueStreams
      }

    if @fields.agency
      @$subTypeDropdown = new Dropdown {
        valueStreams: @fields.subType.valueStreams
      }
      @$agencyDropdown = new Dropdown {
        valueStreams: @fields.agency.valueStreams
      }
      @$regionDropdown = new Dropdown {
        valueStreams: @fields.region.valueStreams
      }
      @$officeDropdown = new Dropdown {
        valueStreams: @fields.office.valueStreams
      }

    @$mapButton = new PrimaryButton()
    @$currentLocationButton = new SecondaryButton()

    subType = @fields.subType?.valueStreams.switch()
    agency = @fields.agency?.valueStreams.switch()
    region = @fields.region?.valueStreams.switch()
    if agency and region
      agencyAndRegion = RxObservable.combineLatest(
        agency, region, (vals...) -> vals
      )

    @state = z.state {
      nameValue: @fields.name.valueStreams.switch()
      locationValue: @fields.location.valueStreams.switch()
      subTypeValue: subType
      agencyValue: agency
      regionValue: region
      agencies: subType?.switchMap (subType) =>
        if subType is 'public'
          @model.agency.getAll()
        else
          RxObservable.of null
      regions: agency?.switchMap (agency) =>
        if agency
          @model.region.getAllByAgencySlug agency
        else
          RxObservable.of null
      offices: agencyAndRegion?.switchMap ([agency, region]) =>
        if agency and region
          @model.office.getAllByAgencySlugAndRegionSlug agency, region
        else
          RxObservable.of null
    }

  isCompleted: =>
    {nameValue, locationValue} = @state.getValue()
    nameValue and locationValue

  getTitle: =>
    @model.l.get 'newPlacePage.title', {
      replacements: {@prettyType}
    }

  render: =>
    {subTypeValue, agencies, agencyValue, regions, regionValue,
      offices} = @state.getValue()

    z '.z-new-place-initial-info',
      z '.g-grid',
        z 'label.field',
          z '.name', @model.l.get 'newPlaceInitialInfo.placeName', {
            replacements: {@prettyType}
          }
          z @$nameInput,
            hintText: @prettyType

        if @fields.subType and @subTypes
          z 'label.field',
            z '.name', @model.l.get 'newPlaceInitialInfo.placeType'
            z @$subTypeDropdown,
              options: _map @subTypes, (text, key) ->
                {
                  value: key
                  text: text
                }

        z 'label.field.where',
          z '.name', @model.l.get 'newPlaceInitialInfo.where'
          z '.form',
            z '.input',
              z @$locationInput,
                hintText: @model.l.get 'newPlaceInitialInfo.coordinates', {
                  replacements: {@prettyType}
                }

            z '.or', @model.l.get 'general.or'

            z '.button',
              z @$mapButton,
                icon: 'map'
                text: @model.l.get 'newPlaceInitialInfo.coordinatesFromMap'
                onclick: =>
                  @model.overlay.open new CoordinatePickerOverlay {
                    @model, @router
                    onPick: (place) =>
                      lat = Math.round(10000 * place.location.lat) / 10000
                      lon = Math.round(10000 * place.location.lon) / 10000
                      @fields.location.valueStreams.next RxObservable.of(
                        "#{lat}, #{lon}"
                      )
                      Promise.resolve null
                  }

            if navigator?.geolocation
              z '.button',
                z @$currentLocationButton,
                  icon: 'crosshair'
                  isOutline: true
                  text: @model.l.get 'general.currentLocation'
                  onclick: =>
                    MapService.getLocation {@model}
                    .then ({lat, lon}) =>
                      @fields.location.valueStreams.next RxObservable.of(
                        "#{lat}, #{lon}"
                      )

        if @fields.subType and not @subTypes
          [
            z '.field.optional',
              @model.l.get 'newPlaceInitialInfo.optional'
            z 'label.field',
              z '.name', @model.l.get 'newPlaceInitialInfo.landType'
              z @$subTypeDropdown,
                options: [
                  {
                    value: ''
                    text: @model.l.get 'newPlaceInitialInfo.selectLandType'
                  }
                  {
                    value: 'public'
                    text: @model.l.get 'placeInfo.landTypePublic'
                  }
                  {
                    value: 'private'
                    text: @model.l.get 'placeInfo.landTypePrivate'
                  }
                ]
          ]

        if subTypeValue is 'public'
          z 'label.field',
            z '.name', @model.l.get 'newPlaceInitialInfo.agency'
            z @$agencyDropdown,
              options: [
                {
                  value: ''
                  text: @model.l.get 'general.none'
                }
                {
                  value: 'other'
                  text: @model.l.get 'general.other'
                }
              ].concat _map agencies, (agency) ->
                {
                  value: agency.slug
                  text: agency.name
                }

        if subTypeValue is 'public' and agencyValue and agencyValue isnt 'other'
          z 'label.field',
            z '.name', @model.l.get 'newPlaceInitialInfo.region'
            z @$regionDropdown,
              options: [
                {
                  value: ''
                  text: @model.l.get 'general.none'
                }
                {
                  value: 'other'
                  text: @model.l.get 'general.other'
                }
              ].concat _map regions, (region) ->
                {
                  value: region.slug
                  text: region.name
                }

        if subTypeValue is 'public' and regionValue and regionValue isnt 'other' and agencyValue isnt 'other'
          z 'label.field',
            z '.name', @model.l.get 'newPlaceInitialInfo.office'
            z @$officeDropdown,
              options: [
                {
                  value: ''
                  text: @model.l.get 'general.none'
                }
                {
                  value: 'other'
                  text: @model.l.get 'general.other'
                }
              ].concat _map offices, (office) ->
                {
                  value: office.slug
                  text: office.name
                }

        z 'label.field.details',
          z '.name', @model.l.get 'newPlaceInitialInfo.details'
          z @$detailsTextarea,
            hintText: @model.l.get 'newPlaceInitialInfo.placeDetails'
