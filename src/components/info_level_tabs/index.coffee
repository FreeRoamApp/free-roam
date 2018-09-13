z = require 'zorium'
_map = require 'lodash/map'

InfoLevel = require '../info_level'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class InfoLevelTabs
  constructor: ({@model, @router, tabs, selectedTab, key}) ->
    @$infoLevel = new InfoLevel {@model, @router, key}
    @state = z.state {
      tabs
      selectedTab
    }

  render: ({value, min, max, minFlavorText, maxFlavorText}) =>
    {tabs, selectedTab} = @state.getValue()

    z '.z-info-level-tabs',
      z '.tabs',
        _map tabs, ({key, text}) =>
          isSelected = selectedTab is key
          z '.tab', {
            className: z.classKebab {isSelected}
            onclick: =>
              @state.set {selectedTab: key}
          },
            text
      z '.info-level',
        z @$infoLevel, {
          value: value?[selectedTab]
          min, max, minFlavorText, maxFlavorText
        }
