# Bind polyfill (phantomjs doesn't support bind)
# coffeelint: disable=missing_fat_arrows
unless Function::bind
  Function::bind = (oThis) ->

    # closest thing possible to the ECMAScript 5
    # internal IsCallable function
    throw new TypeError(
      'Function.prototype.bind - what is trying to be bound is not callable'
    ) if typeof this isnt 'function'
    aArgs = Array::slice.call(arguments, 1)
    fToBind = this
    fNOP = -> null

    fBound = ->
      fToBind.apply(
        (if this instanceof fNOP and oThis then this else oThis),
        aArgs.concat(Array::slice.call(arguments))
      )

    fNOP:: = @prototype
    fBound:: = new fNOP()
    fBound
# coffeelint: enable=missing_fat_arrows

# Promise polyfill - https://github.com/zolmeister/promiz
Promiz = require 'promiz'
window.Promise = window.Promise or Promiz

# Fetch polyfill - https://github.com/github/fetch
require 'whatwg-fetch'

require 'setimmediate'

# iScroll does a translate transform, but it only does it for one transform
# property (eg transform or webkitTransform). We need to know which one iscroll
# is using, so this is the same code they have to pick one
transformProperty = 'transform'
window.getTransformProperty = ->
  _elementStyle = document.createElement('div').style
  _vendor = do ->
    vendors = [
      't'
      'webkitT'
      'MozT'
      'msT'
      'OT'
    ]
    transform = undefined
    i = 0
    l = vendors.length
    while i < l
      transform = vendors[i] + 'ransform'
      if transform of _elementStyle
        return vendors[i].substr(0, vendors[i].length - 1)
      i += 1
    false

  _prefixStyle = (style) ->
    if _vendor is false
      return false
    if _vendor is ''
      return style
    _vendor + style.charAt(0).toUpperCase() + style.substr(1)

  _prefixStyle 'transform'
