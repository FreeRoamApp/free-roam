z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_kebabCase = require 'lodash/kebabCase'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'

Icon = require '../icon'
FormattedText = require '../formatted_text'
Rating = require '../rating'
MapTooltip = require '../map_tooltip'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceTooltip extends MapTooltip
  constructor: ({@model, @router, @place, @position, @mapSize, @toggleLayer}) ->
    @$closeIcon = new Icon()
    @$directionsIcon = new Icon()
    @$addCampsiteIcon = new Icon()
    @$saveIcon = new Icon()
    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }
    @size = new RxBehaviorSubject {width: 0, height: 0}

    features = @place.switchMap (place) =>
      console.log 'place', place
      if place?.type is 'blm'
        @model.geocoder.getFeaturesFromLocation place.location
      else if place?.type is 'usfs'
        @model.geocoder.getFeaturesFromLocation place.location, {
          file: 'usfs_ranger_districts'
        }
      else
        RxObservable.of false

    placeAndFeatures = RxObservable.combineLatest(
      @place, features, (vals...) -> vals
    )

    @state = z.state {
      @place
      @mapSize
      @size
      $description: new FormattedText {
        text: @place.map (place) -> place?.description
      }
      features: features
      mvums: placeAndFeatures.switchMap ([place, features]) =>
        if features?[0]?.FORESTNAME
          @model.localMap.getAllByRegionSlug _kebabCase(features?[0]?.FORESTNAME), {
            location: place?.location
          }
          .map (mvums) ->
            _map mvums, (mvum) ->
              {
                mvum
                $downloadIcon: new Icon()
              }
        else
          RxObservable.of null
      elevation: @place.switchMap (place) =>
        if place?.type is 'coordinate'
          @model.geocoder.getElevationFromLocation place.location
        else
          RxObservable.of false

      isSaving: false
      isSaved: false
    }

    super

  getThumbnailUrl: (place) =>
    @model.image.getSrcByPrefix place?.thumbnailPrefix, {size: 'tiny'}

  saveCoordinate: =>
    {place} = @state.getValue()

    @state.set isSaving: true
    name = prompt 'Enter a name'
    @model.coordinate.upsert {
      name: name
      location: "#{place.location[1]}, #{place.location[0]}"
    }, {invalidateAll: false}
    .then ({id}) =>
      @model.checkIn.upsert {
        sourceType: 'coordinate'
        sourceId: id
        status: 'planned'
      }
    .then =>
      @state.set isSaving: false, isSaved: true

  render: ({isVisible} = {}) =>
    {place, $description, mapSize, size, isSaving,
      isSaved, features, elevation, mvums} = @state.getValue()

    isVisible ?= Boolean place and Boolean size.width

    anchor = @getAnchor place?.position, mapSize, size
    transform = @getTransform place?.position, anchor

    isDisabled = not place or not (place.type in [
      'campground', 'overnight', 'amenity'
    ])

    if not elevation? or elevation is false
      elevation = '...'

    z "a.z-place-tooltip.anchor-#{anchor}", {
      href: if not isDisabled and place
        @router.get place.type, {slug: place.slug}
      className: z.classKebab {isVisible, @isImageLoaded}
      onclick: (e) =>
        e?.stopPropagation()
        if place?.type is 'hazard' and place?.subType is 'lowClearance'
          [lon, lat] = place.location
          @model.portal.call 'browser.openWindow', {
            url:
              "https://maps.google.com/maps?z=18&t=k&ll=#{lat},#{lon}"
          }
        else if not isDisabled
          e?.preventDefault()
          @router.goOverlay place.type, {slug: place.slug}
      style:
        transform: transform
        webkitTransform: transform
    },
      z '.close',
        z @$closeIcon,
          icon: 'close'
          size: '16px'
          isTouchTarget: false
          color: colors.$bgText54
          onclick: (e) =>
            e?.stopPropagation()
            e?.preventDefault()
            @place.next null
      if place?.thumbnailPrefix
        src = @getThumbnailUrl place
        z '.thumbnail',
          style:
            backgroundImage: "url(#{src})"
      z '.content',
        z '.title', place?.name
        if place?.type is 'coordinate'
          z '.elevation',
            @model.l.get 'placeTooltip.elevation', {replacements: {elevation}}
        if place?.description
          z '.description',
            $description
        if place?.type is 'blm' and features?[0]?.Unit_Nm
          z '.features',
            # TODO: lang
            'Subarea: ' + features?[0]?.Unit_Nm
        else if place?.type is 'usfs' and features?[0]?.DISTRICTNA
          z '.features',
            features?[0]?.DISTRICTNA
            unless _isEmpty mvums
              z '.mvums',
                z '.title', 'MVUMs:'
                _map mvums, ({mvum, $downloadIcon}) =>
                  z '.mvum', {
                    onclick: =>
                      # TODO: zoom map in enough?
                      @toggleLayer {
                        name: @model.l.get 'placesMapContainer.mvum'
                        source:
                          type: 'raster'
                          url: "https://localmaps.freeroam.app/data/#{mvum.slug}.json"
                          tileSize: 256 # built as 512 block size, rendered as this for crisper look
                        layer:
                          id: 'mvum'
                          type: 'raster'
                          source: 'mvum'
                          paint:
                            'raster-opacity': 0.8
                          metadata:
                            zIndex: 2
                      }
                  },
                    z '.text', mvum.name or 'MVUM'
                    z 'a.icon', {
                      href: mvum.url
                      target: '_system'
                      attributes:
                        download: _kebabCase(mvum.name) + '.pdf'
                    },
                      z $downloadIcon,
                        icon: 'download'
                        isTouchTarget: false
                        color: colors.$bgText

        if place?.type is 'coordinate'
          z '.actions',
            z '.action', {
              onclick: =>
                MapService.getDirections {
                  location:
                    lat: place.location[1]
                    lon: place.location[0]
                }, {@model}
            },
              z '.icon',
                z @$directionsIcon,
                  icon: 'directions'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text', @model.l.get 'general.directions'
            z '.action', {
              onclick: =>
                @router.go 'newCampground', {}, {
                  qs:
                    location: Math.round(place.location[1] * 1000) / 1000 +
                              ',' +
                              Math.round(place.location[0] * 1000) / 1000
                }
            },
              z '.icon',
                z @$addCampsiteIcon,
                  icon: 'add-circle'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text', @model.l.get 'placeTooltip.addCampsite'
            z '.action', {
              onclick: @saveCoordinate
            },
              z '.icon',
                z @$saveIcon,
                  icon: 'star'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text',
                if isSaving then @model.l.get 'general.saving'
                else if isSaved then @model.l.get 'general.saved'
                else @model.l.get 'general.save'

        else if place?.type and not (place?.type in ['hazard', 'blm', 'usfs'])
          z '.rating',
            z @$rating
