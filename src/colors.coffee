_defaults = require 'lodash/defaults'
_mapValues = require 'lodash/mapValues'

materialColors = require './material_colors'

colors = _defaults {
  default:
    '--header-500': '#ffffff' # t100
    '--header-500-text': materialColors.$black87
    '--header-500-text-54': materialColors.$black54
    '--header-500-icon': '#D25A00' # primary500

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

    '--secondary-50': '#EDF6F0'
    '--secondary-100': '#D2E7DB'
    '--secondary-200': '#B4D8C3'
    '--secondary-300': '#95C8AA'
    '--secondary-400': '#7FBC98'
    '--secondary-500': '#68B086'
    '--secondary-600': '#60A97E'
    '--secondary-700': '#55A073'
    '--secondary-800': '#4B9769'
    '--secondary-900': '#3A8756'
    '--secondary-100-text': materialColors.$black
    '--secondary-200-text': materialColors.$black
    '--secondary-300-text': materialColors.$black
    '--secondary-400-text': materialColors.$black
    '--secondary-500-text': materialColors.$white
    '--secondary-600-text': materialColors.$white
    '--secondary-700-text': materialColors.$white
    '--secondary-800-text': materialColors.$white
    '--secondary-900-text': materialColors.$white

    # '--tertiary-50': '#FEFEFC'
    # '--tertiary-100': '#FEFBF7'
    # '--tertiary-200': '#FDF9F2'
    # '--tertiary-300': '#FCF7ED'
    # '--tertiary-400': '#FBF5E9'
    # '--tertiary-500': '#FAF3E5'
    # '--tertiary-600': '#F9F1E2'
    # '--tertiary-700': '#F9EFDE'
    # '--tertiary-800': '#F8EDDA'
    # '--tertiary-900': '#FFFFFF'

    # '--tertiary-50': '#FAF1E0 '
    # FIXME: tertiary is a mess
    # '--tertiary-100': '#ffffff'
    # '--tertiary-200': '#FAFAFA'
    # '--tertiary-300': '#f8f8f8'
    # '--tertiary-400': '#f0f0f0'
    # '--tertiary-500': '#eaeaea'
    # '--tertiary-600': '#f8f8f8'
    # '--tertiary-700': '#ffffff'
    # # '--tertiary-800': '#FEFDFA'
    # '--tertiary-900': '#f0f0f0'

    '--tertiary-0': '#FFFFFF',
    '--tertiary-50': '#FAFAFA',
    '--tertiary-100': '#F8F8F8', # changed from f5f5f5
    '--tertiary-200': '#EEEEEE',
    '--tertiary-300': '#E0E0E0',
    '--tertiary-400': '#BDBDBD',
    '--tertiary-500': '#9E9E9E',
    '--tertiary-600': '#757575',
    '--tertiary-700': '#616161',
    '--tertiary-800': '#424242',
    '--tertiary-900': '#212121',


    '--tertiary-0-text': materialColors.$black
    '--tertiary-100-text': materialColors.$black
    '--tertiary-200-text': materialColors.$black
    '--tertiary-200-text-70': materialColors.$black70
    '--tertiary-300-text': materialColors.$black
    '--tertiary-400-text': materialColors.$black
    '--tertiary-500-text': materialColors.$black
    '--tertiary-500-text-70': materialColors.$black70
    '--tertiary-600-text': materialColors.$black
    '--tertiary-700-text': materialColors.$black
    '--tertiary-800-text': materialColors.$black
    '--tertiary-900-text': materialColors.$black

    # '--quaternary-50': '#E2F6F5'
    # '--quaternary-100': '#B6E8E7'
    # '--quaternary-200': '#85D9D7'
    # '--quaternary-300': '#54C9C6'
    # '--quaternary-400': '#2FBEBA'
    # '--quaternary-500': '#0AB2AE'
    # '--quaternary-600': '#09ABA7'
    # '--quaternary-700': '#07A29D'
    # '--quaternary-800': '#059994'
    # '--quaternary-900': '#038A84'
    #
    # '--quaternary-500-text': materialColors.$white

    # '--bg-text': '#B62E00' # primary900
    '--bg-text': materialColors.$black70
    '--bg-text-6': 'rgba(0, 0, 0, 0.06)'
    '--bg-text-12': materialColors.$black12
    '--bg-text-26': materialColors.$black26
    '--bg-text-54': materialColors.$black54
    '--bg-text-70': materialColors.$black70
    '--bg-text-87': materialColors.$black87

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

  '$tertiary0': 'var(--tertiary-0)'
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
  '$tertiary0Text': 'var(--tertiary-0-text)'
  '$tertiary100Text': 'var(--tertiary-100-text)'
  '$tertiary200Text': 'var(--tertiary-200-text)'
  '$tertiary200Text70': 'var(--tertiary-200-text-70)'
  '$tertiary300Text': 'var(--tertiary-300-text)'
  '$tertiary400Text': 'var(--tertiary-400-text)'
  '$tertiary500Text': 'var(--tertiary-500-text)'
  '$tertiary500Text70': 'var(--tertiary-500-text-70)'
  '$tertiary600Text': 'var(--tertiary-600-text)'
  '$tertiary700Text': 'var(--tertiary-700-text)'
  '$tertiary800Text': 'var(--tertiary-800-text)'
  '$tertiary900Text': 'var(--tertiary-900-text)'

  # '$quaternary50': 'var(--quaternary-50)'
  # '$quaternary100': 'var(--quaternary-100)'
  # '$quaternary200': 'var(--quaternary-200)'
  # '$quaternary300': 'var(--quaternary-300)'
  # '$quaternary400': 'var(--quaternary-400)'
  # '$quaternary500': 'var(--quaternary-500)'
  # '$quaternary600': 'var(--quaternary-600)'
  # '$quaternary700': 'var(--quaternary-700)'
  # '$quaternary800': 'var(--quaternary-800)'
  # '$quaternary900': 'var(--quaternary-900)'
  # # '$quaternary90012': 'var(--quaternary-90012)'
  # # '$quaternary90054': 'var(--quaternary-90054)'
  # # '$quaternary100Text': 'var(--quaternary-100-text)'
  # # '$quaternary200Text': 'var(--quaternary-200-text)'
  # # '$quaternary300Text': 'var(--quaternary-300-text)'
  # # '$quaternary400Text': 'var(--quaternary-400-text)'
  # '$quaternary500Text': 'var(--quaternary-500-text)'
  # # '$quaternary500Text70': 'var(--quaternary-500-text-70)'
  # # '$quaternary600Text': 'var(--quaternary-600-text)'
  # # '$quaternary700Text': 'var(--quaternary-700-text)'
  # # '$quaternary800Text': 'var(--quaternary-800-text)'
  # # '$quaternary900Text': 'var(--quaternary-900-text)'

  '$bgText': 'var(--bg-text)'
  '$bgText6': 'var(--bg-text-6)'
  '$bgText12': 'var(--bg-text-12)'
  '$bgText26': 'var(--bg-text-26)'
  '$bgText54': 'var(--bg-text-54)'
  '$bgText70': 'var(--bg-text-70)'
  '$bgText87': 'var(--bg-text-87)'

  '$orange500': '#ff7b45'

  '$salmon500': '#f3a37e'
  '$salmon500Text': '#ffffff'

  '$pacific500': '#30799e'
  '$pacific500Text': '#ffffff'

  '$mustard500': '#f6b944'
  '$mustard500Text': '#ffffff'

  '$white4': 'rgba(255, 255, 255, 0.04)'

  '$black': '#0c0c0c'

  '$green500': '#68B086'
  '$yellow500': '#e9d982'
  '$red500': '#e98383'

  '$blue50026': 'rgba(33, 150, 243, 0.26)'
  '$green50026': 'rgba(76, 175, 80, 0.26)'
  '$red50026': 'rgba(244, 67, 54, 0.26)'
  '$yellow50026': 'rgba(233, 217, 130, 0.26)'

  '$amenitygroceries': '#549a4a'
  '$amenitydump': '#864319'
  '$amenitywater': '#3b7ac1'
  '$amenitylaundry': '#00ff00'
  '$amenitypropane': '#cc4040'
  '$amenitytrash': '#000000'
  '$amenityrecycle': '#0000ff'
  '$amenityshower': '#00bcff'
  '$amenitygas': '#dbad49'

  '$weatherClearDay': '#ffbf4f'
  '$weatherPartlyCloudyDay': '#ffbf4f'
  '$weatherRain': '#4ca1af'
  '$weatherSnow': '#98c9e5'

  '$att': '#0098d6'
  '$sprint': '#f7c810'
  '$tmobile': '#dc0070'
  '$verizon': '#ea0b13'

  '$mapLayerBlm': '#e28b2d'
  '$mapLayerUsfs': '#0c6000'

  '$tabSelected': materialColors.$white
  '$tabUnselected': '#1a1a1a'

  '$tabSelectedAlt': materialColors.$white
  '$tabUnselectedAlt': materialColors.$white54

  '$transparent': 'rgba(0, 0, 0, 0)'
  '$common': '#3e4447'

  getRawColor: (color) ->
    if typeof color is 'string' and matches = color.match(/\(([^)]+)\)/)
      colors.default[matches[1]]
    else
      color
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
      colors.getRawColor color

module.exports = colors
