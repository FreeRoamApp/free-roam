z = require 'zorium'
_map = require 'lodash/map'

Sheet = require '../sheet'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class DataTypesSheet
  constructor: ({@model, dataTypesStream, id}) ->
    @$sheet = new Sheet {
      @model, id
    }

    @state = z.state {
      dataTypes: dataTypesStream
    }

  render: =>
    {dataTypes} = @state.getValue()

    z '.z-filter-sheet',
      z @$sheet,
        isVanilla: true
        # $title: $title
        $content:
          z '.z-data-types-sheet_sheet',
            z '.title', @model.l.get 'placesFiltersOverlay.dataTypesTitle'

            z '.g-grid',
              z '.g-cols',
              _map dataTypes, (type) =>
                {dataType, onclick, $toggle, layer} = type
                z '.g-col.g-xs-12.g-md-12',
                  z 'label.type', {
                    onclick: ->
                      ga? 'send', 'event', 'mapSearch', 'dataType', dataType
                    className: z.classKebab {
                      "#{dataType}": true
                    }
                  },
                    z '.info', {
                      onclick: =>
                        $toggle.toggle()
                    },
                      z '.name', @model.l.get "placeTypes.#{dataType}"
                      z '.description',
                        @model.l.get "placeTypes.#{dataType}Description"
                    z '.toggle', z $toggle
