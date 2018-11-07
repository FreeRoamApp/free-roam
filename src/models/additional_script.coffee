RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_uniq = require 'lodash/uniq'

module.exports = class AdditionalScript
  constructor: ->
    @_css = new RxBehaviorSubject []
    @_js = {}

  getCss: =>
    @_css

  add: (type, script) =>
    if type is 'css'
      @_css.next _uniq @_css.getValue().concat script
    else if type is 'js' and not @_js[script]
      @_js[script] = new Promise (resolve, reject) ->
        $$head = document.getElementsByTagName('head')[0]
        $$script = document.createElement('script')
        $$script.type = 'text/javascript'
        $$script.onload = ->
          setTimeout resolve, 0
        $$script.src = script
        $$head.appendChild $$script
    else
      @_js[script]
