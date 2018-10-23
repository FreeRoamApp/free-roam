RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

class MapService
  getAmenityFilters: ({model}) ->
    [
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'dump'
        name: model.l.get 'amenities.dump'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'water'
        name: model.l.get 'amenities.water'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'groceries'
        name: model.l.get 'amenities.groceries'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'propane'
        name: model.l.get 'amenities.propane'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'gas'
        name: model.l.get 'amenities.gas'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'trash'
        name: model.l.get 'amenities.trash'
        valueSubject: new RxBehaviorSubject null
      }
    ]

  getLowClearanceFilters: ({model}) ->
    [
      {
        field: 'heightInches'
        type: 'maxClearance'
        name: model.l.get 'lowClearance.maxClearance'
        valueSubject: new RxBehaviorSubject null
      }
    ]

  getOvernightFilters: ({model}) ->
    [
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'walmart'
        name: model.l.get 'overnight.walmart'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'restArea'
        name: model.l.get 'overnight.restArea'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'casino'
        name: model.l.get 'overnight.casino'
        valueSubject: new RxBehaviorSubject null
      }
    ]


module.exports = new MapService()
