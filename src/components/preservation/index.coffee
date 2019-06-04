z = require 'zorium'

config = require '../../config'

if window?
  require './index.styl'

module.exports = class Preservation
  constructor: ({@model, @router}) ->
    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-preservation',
      z '.g-grid',
        # z '.h1.title', @model.l.get 'preservation.title'
        z 'p', @model.l.get 'preservation.text1'
        z 'ul',
          z 'li', @model.l.get 'preservation.text1a'
          z 'li', @model.l.get 'preservation.text1b'
          z 'li', @model.l.get 'preservation.text1c'

        z 'p', @model.l.get 'preservation.text2'
        z 'ul',
          z 'li',
            @router.link z 'a', {
              href: 'https://lnt.org/learn/7-principles'
            }, 'Leave No Trace'
          z 'li',
            @router.link z 'a', {
              href: 'https://roadslesstraveled.us/boondocking/'
            }, 'Roads Less Traveled'
          z 'li',
            @router.link z 'a', {
              href: 'https://wheelingit.us/2014/01/17/7-tips-on-boondocking-etiquette-rights-wrongs-plain-common-sense/'
            }, 'Wheeling It'
