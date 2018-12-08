z = require 'zorium'

config = require '../../config'

if window?
  require './index.styl'

module.exports = class Preservation
  constructor: ({@model, @router}) ->
    @state = z.state {}

  render: =>
    {} = @state.getValue()

    ###
Camping continues to grow in popularity and more people than ever are visiting free public lands. At the same time, public land is shrinking, in part due to less-than-respectful campers.

If you want to continue being able to camp close to nature for free, be respectful of the land  and people.

- "Pack it in, Pack it Out", most spots won't have trash cans, so be sure to plan ahead and leave nothing behind. If you see someone else's trash, clean it up
- Don't overstay your welcome. Most boondocking spots have a 14-day limit, so be mindful of this
- Be kind to your neighbors, and especially park hosts!

These folks have put it more elquoently than us, so definitely take some time to read their thoughts:

link to:
Leave No Trace:
Roads Less Traveled:
Wheeling It:

    ###

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
            z 'a', {
              href: 'https://lnt.org/learn/7-principles'
              onclick: (e) =>
                e?.preventDefault()
                @model.portal.call 'browser.openWindow', {
                  url: 'https://lnt.org/learn/7-principles'
                  target: '_system'
                }
            }, 'Leave No Trace'
          z 'li',
            z 'a', {
              href: 'https://roadslesstraveled.us/boondocking/'
              onclick: (e) =>
                e?.preventDefault()
                @model.portal.call 'browser.openWindow', {
                  url: 'https://roadslesstraveled.us/boondocking/'
                  target: '_system'
                }
            }, 'Roads Less Traveled'
          z 'li',
            z 'a', {
              href: 'https://wheelingit.us/2014/01/17/7-tips-on-boondocking-etiquette-rights-wrongs-plain-common-sense/'
              onclick: (e) =>
                e?.preventDefault()
                @model.portal.call 'browser.openWindow', {
                  url: 'https://wheelingit.us/2014/01/17/7-tips-on-boondocking-etiquette-rights-wrongs-plain-common-sense/'
                  target: '_system'
                }
            }, 'Wheeling It'
