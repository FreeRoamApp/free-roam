z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable

PlacesMapContainer = require '../places_map_container'
PlacesList = require '../places_list'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CampgroundNearby
  constructor: ({@model, @router, @overlay$, @place}) ->

    addPlaces = @place.map (place) =>
      unless place
        return []
      [{
        name: place.name
        slug: place.slug
        type: place.type
        location:
          lon: place.location[0]
          lat: place.location[1]
      }]

    mapBounds = @place.switchMap (place) =>
      unless place
        return RxObservable.of {}
      @model.campground.getAmenityBoundsById place.id

    @isCellTowersChecked = new RxBehaviorSubject false

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, @overlay$, initialZoom: 9
      showScale: true, addPlaces, mapBounds, isFilterBarHidden: true
      dataTypes: [
        {
          dataType: 'amenity'
          filters: @getAmenityFilters()
          isChecked: true
        }
        {
          dataType: 'cellTower'
          filters: @getCellTowerFilters()
          isCheckedSubject: @isCellTowersChecked
        }
      ]
    }
    # TODO: better solution than @$placesMapContainer.getPlacesStream()?
    @$placesList = new PlacesList {
      @model, @router, places: @$placesMapContainer.getPlacesStream()
    }

    @state = z.state {
      @isCellTowersChecked
    }

  getAmenityFilters: =>
    []

  getCellTowerFilters: =>
    []

  render: =>
    {isCellTowersChecked} = @state.getValue()

    z '.z-campground-nearby',
      z '.map',
        z @$placesMapContainer
        z '.toggle-cell-towers', {
          onclick: =>
            @isCellTowersChecked.next not isCellTowersChecked
        },
          if isCellTowersChecked
            @model.l.get 'campgroundNearby.hideCellTowers'
          else
            @model.l.get 'campgroundNearby.showCellTowers'
      z '.places-list',
        z @$placesList
