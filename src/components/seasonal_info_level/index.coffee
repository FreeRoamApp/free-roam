z = require 'zorium'
_map = require 'lodash/map'

InfoLevel = require '../info_level'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SeasonalInfoLevel
  constructor: ({@model, @router}) ->
    @$infoLevel = new InfoLevel {@model, @router}
    @state = z.state {
      selectedSeason: 'winter' # TODO actual season
    }

  render: ({value, min, max, minFlavorText, maxFlavorText}) =>
    {selectedSeason} = @state.getValue()

    seasons = ['spring', 'summer', 'fall', 'winter']

    z '.z-seasonal-info-level',
      z '.seasons',
        @model.l.get 'general.season'
        ': '
        _map seasons, (season) =>
          isSelected = selectedSeason is season
          z '.season', {
            className: z.classKebab {isSelected}
            onclick: =>
              @state.set {selectedSeason: season}
          },
            @model.l.get "seasons.#{season}"
      z '.info-level',
        z @$infoLevel, {
          value: value?[selectedSeason]
          min, max, minFlavorText, maxFlavorText
        }
