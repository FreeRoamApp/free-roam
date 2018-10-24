z = require 'zorium'
_map = require 'lodash/map'
_flatten = require 'lodash/flatten'
_range = require 'lodash/range'
_filter = require 'lodash/filter'

if window?
  require './index.styl'

module.exports = class MasonryGrid
  constructor: ({@model}) ->
    @state = z.state {
      breakpoint: @model.window.getBreakpoint()
    }

  render: ({$elements, columnCounts}) =>
    {breakpoint} = @state.getValue()

    columnCount = columnCounts[breakpoint or 'mobile'] or columnCounts['mobile']
    if columnCount is 1
      $sortedElements = $elements
    else
      $sortedElements = _flatten _map _range(columnCount), (columnIndex) ->
        _filter $elements, (element, i) ->
          i % columnCount is columnIndex


    z '.z-masonry-grid', {
      style:
        columnCount: columnCount
        webkitColumnCount: columnCount
    },
      _map $sortedElements, ($el) ->
        z '.column', $el
