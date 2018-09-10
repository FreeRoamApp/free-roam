z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'

Icon = require '../icon'
SeasonalInfoLevel = require '../seasonal_info_level'
InfoLevel = require '../info_level'
EmbeddedVideo = require '../embedded_video'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceInfo
  constructor: ({@model, @router, place}) ->
    @$crowdLevelSeasonalInfoLevel = new SeasonalInfoLevel {@model, @router}
    @$fullnessLevelSeasonalInfoLevel = new SeasonalInfoLevel {@model, @router}
    @$noiseLevelInfoLevel = new InfoLevel {@model, @router}
    @$shadeLevelInfoLevel = new InfoLevel {@model, @router}
    @$safetyLevelInfoLevel = new InfoLevel {@model, @router}
    @$roadDifficultyLevelInfoLevel = new InfoLevel {@model, @router}

    @state = z.state
      place: place.map (place) =>
        {
          place
          $videos: _map place.videos, (video) =>
            new EmbeddedVideo {@model, video}
        }

  render: =>
    {place} = @state.getValue()

    {place, $videos} = place or {}

    z '.z-place-info',
      z '.g-grid',
        z '.subhead', @model.l.get 'campground.drivingInstructions'
        place?.drivingInstructions

        z '.g-cols',
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'crowdLevel.title'
            z @$crowdLevelSeasonalInfoLevel, {
              value: place?.crowdLevel
              min: 0
              max: 10
              minFlavorText: @model.l.get 'crowdLevel.minFlavorText'
              maxFlavorText: @model.l.get 'crowdLevel.maxFlavorText'
            }
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'fullnessLevel.title'
            z @$fullnessLevelSeasonalInfoLevel, {
              value: place?.fullnessLevel
              min: 0
              max: 10
              minFlavorText: @model.l.get 'fullnessLevel.minFlavorText'
              maxFlavorText: @model.l.get 'fullnessLevel.maxFlavorText'
            }
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'noiseLevel.title'
            z @$noiseLevelInfoLevel, {
              value: place?.noiseLevel
              min: 0
              max: 10
              minFlavorText: @model.l.get 'noiseLevel.minFlavorText'
              maxFlavorText: @model.l.get 'noiseLevel.maxFlavorText'
            }
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'shadeLevel.title'
            z @$shadeLevelInfoLevel, {
              value: place?.shadeLevel
              min: 0
              max: 10
              minFlavorText: @model.l.get 'shadeLevel.minFlavorText'
              maxFlavorText: @model.l.get 'shadeLevel.maxFlavorText'
            }
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'safetyLevel.title'
            z @$safetyLevelInfoLevel, {
              value: place?.safetyLevel
              min: 0
              max: 10
              minFlavorText: @model.l.get 'safetyLevel.minFlavorText'
              maxFlavorText: @model.l.get 'safetyLevel.maxFlavorText'
            }
          z '.g-col.g-xs-12.g-md-6',
            z '.subhead', @model.l.get 'roadDifficulty.title'
            z @$roadDifficultyLevelInfoLevel, {
              value: place?.roadDifficulty
              min: 0
              max: 10
              minFlavorText: @model.l.get 'roadDifficulty.minFlavorText'
              maxFlavorText: @model.l.get 'roadDifficulty.maxFlavorText'
            }

          unless _isEmpty $videos
            z '.g-col.g-xs-12.g-md-6',
              z '.subhead', @model.l.get 'general.videos'
              z '.videos'
                _map $videos, ($video) ->
                  z $video
