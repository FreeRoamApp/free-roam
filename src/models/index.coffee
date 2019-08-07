Exoid = require 'exoid'
_isEmpty = require 'lodash/isEmpty'
_isPlainObject = require 'lodash/isPlainObject'
_defaults = require 'lodash/defaults'
_merge = require 'lodash/merge'
_pick = require 'lodash/pick'
_map = require 'lodash/map'
_zipWith = require 'lodash/zipWith'
_differenceWith = require 'lodash/differenceWith'
_isEqual = require 'lodash/isEqual'
_keys = require 'lodash/keys'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/operator/take'

Auth = require './auth'
Agency = require './agency'
Amenity = require './amenity'
AmenityAttachment = require './amenity_attachment'
AmenityReview = require './amenity_review'
AdditionalScript = require './additional_script'
Ban = require './ban'
Campground = require './campground'
CampgroundAttachment = require './campground_attachment'
CampgroundReview = require './campground_review'
Category = require './category'
CellTower = require './cell_tower'
CheckIn = require './check_in'
Connection = require './connection'
ConversationMessage = require './conversation_message'
Conversation = require './conversation'
Coordinate = require './coordinate'
Cookie = require './cookie'
# EarnAction = require './earn_action'
Experiment = require './experiment'
Event = require './event'
Geocoder = require './geocoder'
Gif = require './gif'
Group = require './group'
GroupAuditLog = require './group_audit_log'
GroupUser = require './group_user'
GroupRole = require './group_role'
Hazard = require './hazard'
Image = require './image'
Item = require './item'
Language = require './language'
LoginLink = require './login_link'
LocalMap = require './local_map'
Notification = require './notification'
Office = require './office'
OfflineData = require './offline_data'
Overnight = require './overnight'
OvernightAttachment = require './overnight_attachment'
OvernightReview = require './overnight_review'
Payment = require './payment'
Product = require './product'
PlaceAttachmentBase = require './place_attachment_base'
PlaceBase = require './place_base'
PlaceReviewBase = require './place_review_base'
PushToken = require './push_token'
Region = require './region'
StatusBar = require './status_bar'
Subscription = require './subscription'
Thread = require './thread'
Comment = require './comment'
Vote = require './vote'
Time = require './time'
Transaction = require './transaction'
Trip = require './trip'
TripFollower = require './trip_follower'
User = require './user'
UserBlock = require './user_block'
UserData = require './user_data'
UserLocation = require './user_location'
UserRig = require './user_rig'
UserSettings = require './user_settings'
Drawer = require './drawer'
EarnAlert = require './earn_alert'
Overlay = require './overlay'
Tooltip = require './tooltip'
InstallOverlay = require './install_overlay'
Window = require './window'
request = require '../services/request'

config = require '../config'

SERIALIZATION_KEY = 'MODEL'
# SERIALIZATION_EXPIRE_TIME_MS = 1000 * 10 # 10 seconds

module.exports = class Model
  constructor: (options) ->
    {serverHeaders, io, @portal, language,
      initialCookies, setCookie, host} = options
    serverHeaders ?= {}

    cache = window?[SERIALIZATION_KEY] or {}
    window?[SERIALIZATION_KEY] = null
    # maybe this means less memory used for long caches?
    document?.querySelector('.model')?.innerHTML = ''

    # isExpired = if serialization.expires?
    #   # Because of potential clock skew we check around the value
    #   delta = Math.abs(Date.now() - serialization.expires)
    #   delta > SERIALIZATION_EXPIRE_TIME_MS
    # else
    #   true
    # cache = if isExpired then {} else serialization
    @isFromCache = not _isEmpty cache

    userAgent = serverHeaders['user-agent'] or navigator?.userAgent

    ioEmit = (event, opts) =>
      accessToken = @cookie.get 'accessToken'
      io.emit event, _defaults {accessToken, userAgent}, opts

    proxy = (url, opts) =>
      accessToken = @cookie.get 'accessToken'
      proxyHeaders =  _pick serverHeaders, [
        'cookie'
        'user-agent'
        'accept-language'
        'x-forwarded-for'
      ]
      request url, _merge {
        responseType: 'json'
        query: if accessToken? then {accessToken} else {}
        headers: if _isPlainObject opts?.body
          _merge {
            # Avoid CORS preflight
            'Content-Type': 'text/plain'
          }, proxyHeaders
        else
          proxyHeaders
      }, opts

    if navigator?.onLine
      offlineCache = null
    else
      offlineCache = try
        JSON.parse localStorage?.offlineCache
      catch
        {}

    @initialCache = _defaults offlineCache, cache.exoid

    @exoid = new Exoid
      ioEmit: ioEmit
      io: io
      cache: @initialCache
      isServerSide: not window?

    pushToken = new RxBehaviorSubject null

    @cookie = new Cookie {initialCookies, setCookie, host}
    @l = new Language {language, @cookie}
    @overlay = new Overlay()

    @auth = new Auth {@exoid, @cookie, pushToken, @l, userAgent, @portal}

    @additionalScript = new AdditionalScript()
    @agency = new Agency {@auth}
    @amenity = new Amenity {@auth}
    @amenityAttachment = new AmenityAttachment {@auth}
    @amenityReview = new AmenityReview {@auth, @exoid, proxy}
    @ban = new Ban {@auth}
    @category = new Category {@auth}
    @campground = new Campground {@auth}
    @campgroundAttachment = new CampgroundAttachment {@auth}
    @campgroundReview = new CampgroundReview {@auth, @exoid, proxy}
    @comment = new Comment {@auth}
    @cellTower = new CellTower {@auth}
    @checkIn = new CheckIn {@auth, proxy, @l}
    @connection = new Connection {@auth}
    @conversationMessage = new ConversationMessage {@auth, proxy, @exoid}
    @conversation = new Conversation {@auth}
    @coordinate = new Coordinate {@auth}
    # @earnAction = new EarnAction {@auth}
    @event = new Event {@auth}
    @experiment = new Experiment {@cookie}
    @geocoder = new Geocoder {@auth}
    @gif = new Gif()
    @group = new Group {@auth}
    @groupAuditLog = new GroupAuditLog {@auth}
    @groupUser = new GroupUser {@auth}
    @groupRole = new GroupRole {@auth}
    @hazard = new Hazard {@auth}
    @image = new Image {@additionalScript}
    @item = new Item {@auth}
    @loginLink = new LoginLink {@auth}
    @localMap = new LocalMap {@auth}
    @notification = new Notification {@auth}
    @office = new Office {@auth}
    @overnight = new Overnight {@auth}
    @overnightAttachment = new OvernightAttachment {@auth}
    @overnightReview = new OvernightReview {@auth, @exoid, proxy}
    @payment = new Payment {@auth}
    @placeAttachment = new PlaceAttachmentBase {@auth}
    @placeBase = new PlaceBase {@auth, @l}
    @placeReview = new PlaceReviewBase {@auth}
    @product = new Product {@auth}
    @pushToken = new PushToken {@auth, pushToken}
    @region = new Region {@auth}
    @statusBar = new StatusBar {}
    @subscription = new Subscription {@auth}
    @thread = new Thread {@auth, @l, @group, @exoid, proxy}
    @transaction = new Transaction {@auth}
    @time = new Time {@auth}
    @trip = new Trip {@auth, proxy, @exoid}
    @tripFollower = new TripFollower {@auth}
    @user = new User {@auth, proxy, @exoid, @cookie, @l, @overlay, @portal, @router}
    @userBlock = new UserBlock {@auth}
    @userData = new UserData {@auth}
    @userLocation = new UserLocation {@auth}
    @userRig = new UserRig {@auth}
    @userSettings = new UserSettings {@auth}
    @vote = new Vote {@auth}

    @drawer = new Drawer()
    @earnAlert = new EarnAlert()
    @installOverlay = new InstallOverlay {@l, @overlay}
    @tooltip = new Tooltip()
    @offlineData = new OfflineData {@exoid, @portal, @statusBar, @l}
    @portal?.setModels {
      @user, @pushToken, @l, @installOverlay, @overlay
    }
    @window = new Window {@cookie, @experiment, userAgent}

  # after page has loaded, refetch all initial (cached) requests to verify they're still up-to-date
  validateInitialCache: =>
    cache = @initialCache
    @initialCache = null

    # could listen for postMessage from service worker to see if this is from
    # cache, then validate data
    requests = _map cache, (result, key) =>
      req = try
        JSON.parse key
      catch
        RxObservable.of null

      if req.path
        @auth.stream req.path, req.body, {ignoreCache: true} #, options

    # TODO: seems to use anon cookie for this. not sure how to fix...
    # i guess keep initial cookie stored and run using that?

    # so need to handle the case where the cookie changes between server-side
    # cache and the actual get (when user doesn't exist from exoid, but cookie gets user)

    RxObservable.combineLatest(
      requests, (vals...) -> vals
    )
    .take(1).subscribe (responses) =>
      responses = _zipWith responses, _keys(cache), (response, req) ->
        {req, response}
      cacheArray = _map cache, (response, req) ->
        {req, response}
      # see if our updated responses differ from the cached data.
      changedReqs = _differenceWith(responses, cacheArray, _isEqual)
      # update with new values
      _map changedReqs, ({req, response}) =>
        console.log 'OUTDATED EXOID:', req, 'replacing...', response
        @exoid.setDataCache req, response

      # there's a change this will be invalidated every time
      # eg. if we add some sort of timer / visitCount to user.getMe
      # i'm not sure if that's a bad thing or not. some people always
      # load from cache then update, and this would basically be the same
      unless _isEmpty changedReqs
        console.log 'invalidating html cache...'
        @portal.call 'cache.deleteHtmlCache'
        # FIXME TODO invalidate in service worker


  wasCached: => @isFromCache

  dispose: =>
    @time.dispose()
    @exoid.disposeAll()

  getSerializationStream: =>
    @exoid.getCacheStream()
    .map (exoidCache) ->
      string = JSON.stringify({
        exoid: exoidCache
        # problem with this is clock skew
        # expires: Date.now() + SERIALIZATION_EXPIRE_TIME_MS
      }).replace /<\/script/gi, '<\\/script'
      "window['#{SERIALIZATION_KEY}']=#{string};"
