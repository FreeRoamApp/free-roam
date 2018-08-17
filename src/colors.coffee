_defaults = require 'lodash/defaults'
_mapValues = require 'lodash/mapValues'

materialColors = require './material_colors'

colors = _defaults {
  default:
    '--header-500': '#FAF3E5' # t500
    '--header-500-text': materialColors.$black
    '--header-500-text-54': materialColors.$black54
    '--header-500-icon': '#D25A00' # p500

    '--primary-50': '#FAEBE0'
    '--primary-100': '#F2CEB3'
    '--primary-200': '#E9AD80'
    '--primary-300': '#E08C4D'
    '--primary-400': '#D97326'
    '--primary-500': '#D25A00'
    '--primary-50096': 'rgba(210, 90, 0, 0.96)'
    '--primary-600': '#CD5200'
    '--primary-700': '#C74800'
    '--primary-800': '#C13F00'
    '--primary-900': '#B62E00'
    '--primary-100-text': materialColors.$white
    '--primary-200-text': materialColors.$white
    '--primary-300-text': materialColors.$white
    '--primary-400-text': materialColors.$white
    '--primary-500-text': materialColors.$white
    '--primary-600-text': materialColors.$white
    '--primary-700-text': materialColors.$white
    '--primary-800-text': materialColors.$white
    '--primary-900-text': materialColors.$white

    '--secondary-50': '#FFF6F1'
    '--secondary-100': '#FFE9DC'
    '--secondary-200': '#FFDBC4'
    '--secondary-300': '#FFCCAC'
    '--secondary-400': '#FFC19B'
    '--secondary-500': '#FFB689'
    '--secondary-600': '#FFAF81'
    '--secondary-700': '#FFA676'
    '--secondary-800': '#FF9E6C'
    '--secondary-900': '#FF8E5'
    '--secondary-100-text': materialColors.$black
    '--secondary-200-text': materialColors.$black
    '--secondary-300-text': materialColors.$black
    '--secondary-400-text': materialColors.$black
    '--secondary-500-text': materialColors.$black
    '--secondary-600-text': materialColors.$black
    '--secondary-700-text': materialColors.$black
    '--secondary-800-text': materialColors.$black
    '--secondary-900-text': materialColors.$black

    '--tertiary-50': '#FEFEFC'
    '--tertiary-100': '#FEFBF7'
    '--tertiary-200': '#FDF9F2'
    '--tertiary-300': '#FCF7ED'
    '--tertiary-400': '#FBF5E9'
    '--tertiary-500': '#FAF3E5'
    '--tertiary-600': '#F9F1E2'
    '--tertiary-700': '#F9EFDE'
    '--tertiary-800': '#F8EDDA'
    '--tertiary-900': '#FFFFFF'
    # '--tertiary-900': '#F6EAD'
    '--tertiary-100-text': materialColors.$black
    '--tertiary-200-text': materialColors.$black
    '--tertiary-300-text': materialColors.$black
    '--tertiary-400-text': materialColors.$black
    '--tertiary-500-text': materialColors.$black
    '--tertiary-500-text-70': materialColors.$black70
    '--tertiary-600-text': materialColors.$black
    '--tertiary-700-text': materialColors.$black
    '--tertiary-800-text': materialColors.$black
    '--tertiary-900-text': materialColors.$black
    '--tertiary-900-text-6': 'rgba(0, 0, 0, 0.06)'
    '--tertiary-900-text-12': materialColors.$black12
    '--tertiary-900-text-54': materialColors.$black54

    '--test-color': '#000' # don't change








  '$header500': 'var(--header-500)'
  '$header500Text': 'var(--header-500-text)'
  '$header500Text54': 'var(--header-500-text54)'
  '$header500Icon': 'var(--header-500-icon)'

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

  '$primary100Text': 'var(--primary-100-text)'
  '$primary200Text': 'var(--primary-200-text)'
  '$primary300Text': 'var(--primary-300-text)'
  '$primary400Text': 'var(--primary-400-text)'
  '$primary500Text': 'var(--primary-500-text)'
  '$primary600Text': 'var(--primary-600-text)'
  '$primary700Text': 'var(--primary-700-text)'
  '$primary800Text': 'var(--primary-800-text)'
  '$primary900Text': 'var(--primary-900-text)'

  '$secondary100': 'var(--secondary-100)'
  '$secondary200': 'var(--secondary-200)'
  '$secondary300': 'var(--secondary-300)'
  '$secondary400': 'var(--secondary-400)'
  '$secondary500': 'var(--secondary-500)'
  '$secondary600': 'var(--secondary-600)'
  '$secondary700': 'var(--secondary-700)'
  '$secondary800': 'var(--secondary-800)'
  '$secondary900': 'var(--secondary-900)'

  '$secondary100Text': 'var(--secondary-100-text)'
  '$secondary200Text': 'var(--secondary-200-text)'
  '$secondary300Text': 'var(--secondary-300-text)'
  '$secondary500Text': 'var(--secondary-500-text)'
  '$secondary500Text': 'var(--secondary-500-text)'
  '$secondary600Text': 'var(--secondary-600-text)'
  '$secondary700Text': 'var(--secondary-700-text)'
  '$secondary800Text': 'var(--secondary-800-text)'
  '$secondary900Text': 'var(--secondary-900-text)'

  '$tertiary50': 'var(--tertiary-50)'
  '$tertiary100': 'var(--tertiary-100)'
  '$tertiary200': 'var(--tertiary-200)'
  '$tertiary900Text54': 'var(--tertiary-300)'
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
  '$tertiary900Text54Text': 'var(--tertiary-300-text)'
  '$tertiary400Text': 'var(--tertiary-400-text)'
  '$tertiary500Text': 'var(--tertiary-500-text)'
  '$tertiary500Text70': 'var(--tertiary-500-text-70)'
  '$tertiary600Text': 'var(--tertiary-600-text)'
  '$tertiary700Text': 'var(--tertiary-700-text)'
  '$tertiary800Text': 'var(--tertiary-800-text)'
  '$tertiary900Text': 'var(--tertiary-900-text)'
  '$tertiary900Text6': 'var(--tertiary-900-text-6)'
  '$tertiary900Text12': 'var(--tertiary-900-text-12)'
  '$tertiary900Text54': 'var(--tertiary-900-text-54)'

  '$quaternary500': '#ff7b45'

  '$white4': 'rgba(255, 255, 255, 0.04)'
  '$white54': 'rgba(255, 255, 255, 0.54)'

  '$black': '#0c0c0c'

  '$blue50026': 'rgba(33, 150, 243, 0.26)'
  '$green50026': 'rgba(76, 175, 80, 0.26)'
  '$red50026': 'rgba(244, 67, 54, 0.26)'

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
