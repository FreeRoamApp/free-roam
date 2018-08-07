RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable

module.exports = class Base
  clearOnUnmount: (observable) =>
    @clearObservable = new RxBehaviorSubject {}
    return RxObservable.merge @clearObservable, observable

  beforeUnmount: =>
    console.log 'bunext'
    @clearObservable.next {}
