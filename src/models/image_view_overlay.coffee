RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

module.exports = class ImageViewOverlay
  constructor: ->
    @imageData = new RxBehaviorSubject null

  getImageData: =>
    @imageData

  setImageData: (imageData) =>
    @imageData.next imageData
