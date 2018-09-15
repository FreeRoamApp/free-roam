RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/merge'

module.exports = class Base
  clearOnUnmount: (observable) =>
    @clearObservableStreams = new RxReplaySubject 1
    return RxObservable.merge @clearObservableStreams.switch(), observable

  beforeUnmount: =>
    @clearObservableStreams.next RxObservable.of null
