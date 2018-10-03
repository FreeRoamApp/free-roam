z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_mapValues = require 'lodash/mapValues'
_isEmpty = require 'lodash/isEmpty'
_keys = require 'lodash/keys'

NewCampgroundInitialInfo = require '../new_campground_initial_info'
NewReviewExtras = require '../new_review_extras'
StepBar = require '../step_bar'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# editing can probably be its own component. Editing just needs name, text fields, # of sites, and location
# auto-generated: cell, all sliders
# new campground is trying to source a lot more

# step 1 is add new campsite, then just go through review steps, but all are mandatory


module.exports = class NewCampground
  constructor: ({@model, @router, @overlay$}) ->
    me = @model.user.getMe()

    @step = new RxBehaviorSubject 2
    @$stepBar = new StepBar {@model, @step}

    @season = new RxBehaviorSubject @model.time.getCurrentSeason()

    @fields =
      name:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      location:
        valueSubject: new RxBehaviorSubject ''
        errorSubject: new RxBehaviorSubject null
      siteCount:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      crowds:
        isSeasonal: true
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      fullness:
        isSeasonal: true
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      noise:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      shade:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      roadDifficulty:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      cellSignal:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      safety:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      minPrice:
        valueSubject: new RxBehaviorSubject 'free'
        errorSubject: new RxBehaviorSubject null
      maxDays:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      restrooms:
        valueSubject: new RxBehaviorSubject null
        errorSubject: new RxBehaviorSubject null
      videos:
        valueSubject: new RxBehaviorSubject []
        errorSubject: new RxBehaviorSubject null

    @$steps = [
      new NewCampgroundInitialInfo {
        @model, @router, @fields, @season, @overlay$
      }
      new NewReviewExtras {
        @model, @router, @fields, @season, @overlay$
      }
    ]

    @state = z.state {
      @step
    }

  upsert: =>
    # @model.campgroundReview.upsert
    console.log _mapValues @fields, ({valueSubject, isSeasonal}) =>
      value = valueSubject.getValue()
      if isSeasonal and value?
        season = @season.getValue()
        {"#{season}": value}
      else if not isSeasonal
        value

  render: =>
    {step} = @state.getValue()

    console.log 'render', _mapValues @fields, ({valueSubject, isSeasonal}) =>
      value = valueSubject.getValue()
      if isSeasonal and value?
        season = @season.getValue()
        {"#{season}": value}
      else if not isSeasonal
        value

    z '.z-new-campground',
      z @$steps[step]

      z @$stepBar, {
        isSaving: false
        steps: 3
        isStepCompleted: @$steps[step]?.isCompleted?()
        save:
          icon: 'arrow-right'
          onclick: (e) => null
      }
    ###
    name
    location
    address?
    siteCount?
    crowds
    fullness
    noise
    shade
    roadDifficulty
    cellSignal
    safety
    minPrice (free)
    maxDays
    restrooms
    videos

    -> nearby amenities?
    ###
