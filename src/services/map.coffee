class MapService
  getAmenityFilters: ({model}) ->
    [
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'dump'
        name: model.l.get 'amenities.dump'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'water'
        name: model.l.get 'amenities.water'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'groceries'
        name: model.l.get 'amenities.groceries'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'propane'
        name: model.l.get 'amenities.propane'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'gas'
        name: model.l.get 'amenities.gas'
      }
      {
        field: 'amenities'
        type: 'booleanArray'
        arrayValue: 'trash'
        name: model.l.get 'amenities.trash'
      }
    ]

  getCampgroundFilters: ({model}) =>
    [
      {
        field: 'cellSignal'
        type: 'cellSignal'
        name: model.l.get 'campground.cellSignal'
      }
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: model.l.get 'campground.roadDifficulty'
      }
      {
        field: 'crowds'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.crowds'
      }
      {
        field: 'weather'
        type: 'weather'
        name: model.l.get 'general.weather'
      }
      {
        field: 'distanceTo'
        type: 'distanceTo'
        name: model.l.get 'campground.distanceTo'
      }
      {
        field: 'safety'
        type: 'minInt'
        name: model.l.get 'campground.safety'
      }
      {
        field: 'noise'
        type: 'maxIntDayNight'
        name: model.l.get 'campground.noise'
      }
      {
        field: 'fullness'
        type: 'maxIntSeasonal'
        name: model.l.get 'campground.fullness'
      }
      {
        field: 'shade'
        type: 'maxInt'
        name: model.l.get 'campground.shade'
      }
    ]

  getLowClearanceFilters: ({model}) ->
    [
      {
        field: 'heightInches'
        type: 'maxClearance'
        name: model.l.get 'lowClearance.maxClearance'
      }
    ]

  getOvernightFilters: ({model}) ->
    [
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'walmart'
        name: model.l.get 'overnight.walmart'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'restArea'
        name: model.l.get 'overnight.restArea'
      }
      {
        field: 'subType'
        type: 'booleanArray'
        arrayValue: 'casino'
        name: model.l.get 'overnight.casino'
      }
    ]


module.exports = new MapService()
