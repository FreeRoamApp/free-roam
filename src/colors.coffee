_defaults = require 'lodash/defaults'
_mapValues = require 'lodash/mapValues'

materialColors = require './material_colors'

colors = _defaults {
  default:
    '--header-500': '#171a1c' # t700
    '--header-500-text': materialColors.$white
    '--header-500-text-54': materialColors.$white54
    '--header-500-icon': '#ff8a00' # p500

    '--primary-100': materialColors.$orange100
    '--primary-200': materialColors.$orange200
    '--primary-300': materialColors.$orange300
    '--primary-400': materialColors.$orange300
    '--primary-500': '#ff8a00'
    '--primary-50096': 'rgba(255, 138, 0, 0.96)'
    '--primary-600': materialColors.$orange600
    '--primary-700': '#e86f00'
    '--primary-800': materialColors.$orange800
    '--primary-900': materialColors.$orange900
    '--primary-500-text': materialColors.$white

    '--tertiary-100': materialColors.$grey100
    '--tertiary-200': materialColors.$grey200
    '--tertiary-300': '#84898a'
    '--tertiary-400': '#3e4447'
    '--tertiary-500': '#202527'
    '--tertiary-600': '#1d2226'
    '--tertiary-700': '#171a1c'
    '--tertiary-800': materialColors.$grey800
    '--tertiary-900': '#0e1011'
    '--tertiary-90012': 'rgba(0, 0, 0, 0.12)'
    '--tertiary-90054': 'rgba(0, 0, 0, 0.54)'
    '--tertiary-100-text': materialColors.$white
    '--tertiary-200-text': materialColors.$white
    '--tertiary-300-text': materialColors.$white
    '--tertiary-400-text': materialColors.$white
    '--tertiary-500-text': materialColors.$white
    '--tertiary-500-text-70': materialColors.$white70
    '--tertiary-600-text': materialColors.$white
    '--tertiary-700-text': materialColors.$white
    '--tertiary-800-text': materialColors.$white
    '--tertiary-900-text': materialColors.$white
    '--tertiary-900-text-12': materialColors.$white12
    '--tertiary-900-text-54': materialColors.$white54

    '--test-color': '#000' # don't change








  '$header500': 'var(--header-500)'
  '$header500Text': 'var(--header-500-text)'
  '$header500Text54': 'var(--header-500-text54)'
  '$header500Icon': 'var(--header-500-icon)'

  '$drawerHeader500': 'var(--drawer-header-500)'
  '$drawerHeader500Text': 'var(--drawer-header-500-text)'

  '$primary50': 'var(--primary-50)'
  '$primary100': 'var(--primary-100)'
  '$primary200': 'var(--primary-200)'
  '$primary300': 'var(--primary-300)'
  '$primary400': 'var(--primary-400)'
  '$primary500': 'var(--primary-500)'
  '$primary50096': 'var(--primary-50096)'
  '$primary600': 'var(--primary-600)'
  '$primary700': 'var(--primary-700)'
  '$primary800': 'var(--primary-800)'
  '$primary900': 'var(--primary-900)'

  '$primary500Text': 'var(--primary-500-text)'

  # TODO: move rest to vars
  '$primary100Text': materialColors.$red900Text
  '$primary200Text': materialColors.$red900Text
  '$primary300Text': materialColors.$red900Text
  '$primary400Text': materialColors.$red900Text

  '$primary600Text': materialColors.$red600Text
  '$primary700Text': materialColors.$red700Text
  '$primary800Text': materialColors.$red800Text
  '$primary900Text': materialColors.$red900Text

  '$secondary100': materialColors.$white
  '$secondary200': materialColors.$white
  '$secondary300': materialColors.$white
  '$secondary400': materialColors.$white
  '$secondary500': '#ffc800'
  '$secondary600': materialColors.$white
  '$secondary700': materialColors.$white
  '$secondary800': materialColors.$white
  '$secondary900': materialColors.$white
  '$secondary100Text': materialColors.$blueGrey900
  '$secondary200Text': materialColors.$blueGrey900
  '$secondary300Text': materialColors.$blueGrey900
  '$secondary400Text': materialColors.$blueGrey900
  '$secondary500Text': materialColors.$blueGrey900
  '$secondary600Text': materialColors.$blueGrey900
  '$secondary700Text': materialColors.$blueGrey900
  '$secondary800Text': materialColors.$blueGrey900
  '$secondary900Text': materialColors.$blueGrey900


  '$tertiary50': 'var(--tertiary-50)'
  '$tertiary100': 'var(--tertiary-100)'
  '$tertiary200': 'var(--tertiary-200)'
  '$tertiary300': 'var(--tertiary-300)'
  '$tertiary400': 'var(--tertiary-400)'
  '$tertiary500': 'var(--tertiary-500)'
  '$tertiary600': 'var(--tertiary-600)'
  '$tertiary700': 'var(--tertiary-700)'
  '$tertiary800': 'var(--tertiary-800)'
  '$tertiary900': 'var(--tertiary-900)'
  '$tertiary90012': 'var(--tertiary-90012)'
  '$tertiary90054': 'var(--tertiary-90054)'
  '$tertiary100Text': 'var(--tertiary-100-text)'
  '$tertiary200Text': 'var(--tertiary-200-text)'
  '$tertiary300Text': 'var(--tertiary-300-text)'
  '$tertiary400Text': 'var(--tertiary-400-text)'
  '$tertiary500Text': 'var(--tertiary-500-text)'
  '$tertiary500Text70': 'var(--tertiary-500-text-70)'
  '$tertiary600Text': 'var(--tertiary-600-text)'
  '$tertiary700Text': 'var(--tertiary-700-text)'
  '$tertiary800Text': 'var(--tertiary-800-text)'
  '$tertiary900Text': 'var(--tertiary-900-text)'
  '$tertiary900Text12': 'var(--tertiary-900-text-12)'
  '$tertiary900Text54': 'var(--tertiary-900-text-54)'

  '$quaternary500': '#ff7b45'

  '$white4': 'rgba(255, 255, 255, 0.04)'
  '$white54': 'rgba(255, 255, 255, 0.54)'

  '$black': '#0c0c0c'

  '$purple500': '#dd00e2'

  '$tabSelected': materialColors.$white
  '$tabUnselected': '#1a1a1a'

  '$tabSelectedAlt': materialColors.$white
  '$tabUnselectedAlt': materialColors.$white54

  '$transparent': 'rgba(0, 0, 0, 0)'
  '$common': '#3e4447'
  '$rare': materialColors.$blue500
  '$epic': materialColors.$purple500
  '$legendary': materialColors.$orange500
  '$commonText': materialColors.$white
  '$rareText': materialColors.$white
  '$epicText': materialColors.$white
  '$legendaryText': materialColors.$white
}, materialColors

# https://stackoverflow.com/a/4900484
getChromeVersion = ->
  raw = navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./)
  if raw then parseInt(raw[2], 10) else false

# no css-variable support
if window?
  $$el = document.getElementById('css-variable-test')
  isCssVariableSupported = not $$el or
    window.CSS?.supports?('--fake-var', 0) or
    getComputedStyle($$el, null)?.backgroundColor is 'rgb(0, 0, 0)'
  unless isCssVariableSupported
    colors = _mapValues colors, (color, key) ->
      if typeof color is 'string' and matches = color.match(/\(([^)]+)\)/)
        colors.default[matches[1]]
      else
        color

module.exports = colors
