z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_range = require 'lodash/range'

colors = require '../../colors'

if window?
  require './index.styl'

MAX_BARS = 5

module.exports = class CellBars
  # set isInteractive to true if tapping on a star should fill up to that star
  constructor: ({@value, @valueStreams, @isInteractive}) ->
    @value ?= new RxBehaviorSubject 0

    cellBars = @valueStreams?.switch() or @value

    @state = z.state {
      cellBars: cellBars
    }

  setCellBars: (value) =>
    if @valueStreams
      @valueStreams.next RxObservable.of value
    else
      @value.next value

  render: ({widthPx, heightPx} = {}) =>
    {cellBars} = @state.getValue()

    widthPx ?= 30
    heightPx ?= widthPx * 0.5

    z ".z-cell-bars.bars-#{cellBars}", {
      style:
        width: "#{widthPx}px"
        height: "#{heightPx}px"
    },
      _map _range(MAX_BARS), (i) =>
        z ".bar.bar-#{i + 1}", {
          onclick: if @isInteractive then (=> @setCellBars i + 1) else null
          className: z.classKebab {isVisible: cellBars > i}
          style:
            height: "#{(i + 1) * 20}%"
        }
