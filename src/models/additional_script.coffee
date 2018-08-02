RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_uniq = require 'lodash/uniq'

module.exports = class AdditionalScript
  constructor: ->
    @_css = new RxBehaviorSubject []
    @_js = []

  getCss: =>
    @_css

  add: (type, script) =>
    if type is 'css'
      @_css.next _uniq @_css.getValue().concat script
    else if type is 'js' and @_js.indexOf(script) is -1
      @_js = @_js.concat script
      new Promise (resolve, reject) ->
        $$head = document.getElementsByTagName('head')[0]
        $$script = document.createElement('script')
        $$script.type = 'text/javascript'
        $$script.onload = resolve
        $$script.src = script
        $$head.appendChild $$script
    else
      Promise.resolve null
