z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_map = require 'lodash/map'
_kebabCase = require 'lodash/kebabCase'
_startCase = require 'lodash/startCase'
RxObservable = require('rxjs/Observable').Observable

Dialog = require '../dialog'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CoordinateInfoDialog
  constructor: (options) ->
    {@model, @router, @coordinate, @addOptionalLayer,
      @addLayerById, @removeLayerById} = options

    @$dialog = new Dialog {
      onLeave: =>
        @model.overlay.close()
    }


    @state = z.state
      features: RxObservable.combineLatest _map(@coordinate.features, (feature) =>
        location = {
          lat: @coordinate.location[1]
          lon: @coordinate.location[0]
        }
        console.log location
        if feature.source is 'us-blm'
          @model.geocoder.getFeaturesFromLocation location
          .map (features) ->
            features?[0].Loc_Nm
        else if feature.source is 'us-usfs'
          @model.geocoder.getFeaturesFromLocation location, {
            file: 'usfs_ranger_districts'
          }
          .map (features) ->
            features?[0].DISTRICTNA
        else
          RxObservable.of false
      ), (vals...) -> vals
      mvums:
        if @coordinate.features?[0]?.properties.Loc_Nm
          regionSlug = _kebabCase(@coordinate.features?[0]?.properties.Loc_Nm)
          @model.localMap.getAllByRegionSlug regionSlug, {
            location: @coordinate?.location
          }
          .map (mvums) ->
            _map mvums, (mvum) ->
              {
                mvum
                $downloadIcon: new Icon()
                $mapIcon: new Icon()
              }
        else
          null

  render: =>
    {features, mvums} = @state.getValue()
    # area = if properties.Loc_Nm \
    #        then _startCase properties.Loc_Nm.toLowerCase()
    #        else @model.l.get 'general.unknown'
    # access = if properties.Access \
    #          then @model.l.get "coordinateInfoDialog.pla.#{properties.Access}"
    #          else @model.l.get 'general.unknown'

    z '.z-coordinate-info-dialog',
      z @$dialog,
        isVanilla: true
        $title: ''
        $content:
          z '.z-coordinate-info-dialog_dialog',
            _map @coordinate.features, ({source, properties}, i) =>
              if source is 'us-usfs'
                area = if properties.Loc_Nm \
                       then _startCase properties.Loc_Nm.toLowerCase()
                       else @model.l.get 'general.unknown'
                access = if properties.Access \
                         then @model.l.get "coordinateInfoDialog.pla.#{properties.Access}"
                         else @model.l.get 'general.unknown'
                z '.feature',
                  z '.layer', 'USFS'
                  z '.office', features?[i]
                  z '.region',
                    "Forest: #{area}"
                  z '.access',
                    "Access: #{access}"
                  unless _isEmpty mvums
                    z '.mvums',
                      z '.title', 'MVUMs:'
                      _map mvums, ({mvum, $downloadIcon, $mapIcon}) =>
                        z '.mvum', {
                          onclick: =>
                            # TODO: zoom map in enough?
                            @addOptionalLayer {
                              isTemporary: true
                              name: mvum.name
                              defaultOpacity: 0.8
                              source:
                                type: 'raster'
                                url: "https://localmaps.freeroam.app/data/#{mvum.slug}.json"
                                tileSize: 256 # built as 512 block size, rendered as this for crisper look
                              layer:
                                id: mvum.slug
                                type: 'raster'
                                source: mvum.slug
                                paint: {}
                                metadata:
                                  zIndex: 2
                            }
                            @addLayerById mvum.slug
                        },
                          z '.text', mvum.name or 'MVUM'
                          z 'a.download-icon', {
                            href: mvum.url
                            target: '_system'
                            attributes:
                              download: _kebabCase(mvum.name) + '.pdf'
                          },
                            z $downloadIcon,
                              icon: 'download'
                              isTouchTarget: false
                              color: colors.$primary500
                          z '.map-icon',
                            z $mapIcon,
                              icon: 'map-add'
                              isTouchTarget: false
                              color: colors.$primary500

        cancelButton:
          text: @model.l.get 'general.close'
          onclick: =>
            @model.overlay.close()
