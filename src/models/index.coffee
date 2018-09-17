Exoid = require 'exoid'
request = require 'clay-request'
_isEmpty = require 'lodash/isEmpty'
_isPlainObject = require 'lodash/isPlainObject'
_defaults = require 'lodash/defaults'
_merge = require 'lodash/merge'
_pick = require 'lodash/pick'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
require 'rxjs/add/operator/take'

Auth = require './auth'
Ad = require './ad'
AdditionalScript = require './additional_script'
Ban = require './ban'
Category = require './category'
ConversationMessage = require './conversation_message'
Conversation = require './conversation'
Cookie = require './cookie'
Experiment = require './experiment'
Gif = require './gif'
Group = require './group'
GroupAuditLog = require './group_audit_log'
GroupUser = require './group_user'
GroupRole = require './group_role'
Image = require './image'
Item = require './item'
Language = require './language'
Notification = require './notification'
Nps = require './nps'
# reviews
CampgroundReview = require './campground_review'

# places
Amenity = require './amenity'
Campground = require './campground'

Product = require './product'
PushToken = require './push_token'
Thread = require './thread'
ThreadComment = require './thread_comment'
ThreadVote = require './thread_vote'
Time = require './time'
User = require './user'
UserBlock = require './user_block'
UserFollower = require './user_follower'
Drawer = require './drawer'
GetAppDialog = require './get_app_dialog'
SignInDialog = require './sign_in_dialog'
PushNotificationSheet = require './push_notification_sheet'
InstallOverlay = require './install_overlay'
Window = require './window'

config = require '../config'

SERIALIZATION_KEY = 'MODEL'
SERIALIZATION_EXPIRE_TIME_MS = 1000 * 10 # 10 seconds

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
        qs: if accessToken? then {accessToken} else {}
        headers: if _isPlainObject opts?.body
          _merge {
            # Avoid CORS preflight
            'Content-Type': 'text/plain'
          }, proxyHeaders
        else
          proxyHeaders
      }, opts

    @exoid = new Exoid
      ioEmit: ioEmit
      io: io
      cache: cache.exoid
      isServerSide: not window?

    pushToken = new RxBehaviorSubject null

    @cookie = new Cookie {initialCookies, setCookie, host}
    @l = new Language {language, @cookie}

    @auth = new Auth {@exoid, @cookie, pushToken, @l, userAgent, @portal}
    @user = new User {@auth, proxy, @exoid, @cookie, @l}
    @userBlock = new UserBlock {@auth}
    @userFollower = new UserFollower {@auth}
    @ad = new Ad {@portal, @cookie, userAgent}
    @additionalScript = new AdditionalScript()
    @ban = new Ban {@auth}
    @category = new Category {@auth}
    @conversationMessage = new ConversationMessage {@auth, proxy, @exoid}
    @conversation = new Conversation {@auth}
    @experiment = new Experiment {@cookie}
    @gif = new Gif()
    @group = new Group {@auth}
    @groupAuditLog = new GroupAuditLog {@auth}
    @groupUser = new GroupUser {@auth}
    @groupRole = new GroupRole {@auth}
    @image = new Image()
    @item = new Item {@auth}
    @thread = new Thread {@auth, @l, @group, @exoid, proxy}
    @threadComment = new ThreadComment {@auth}
    @threadVote = new ThreadVote {@auth}
    @notification = new Notification {@auth}
    @nps = new Nps {@auth}

    # reviews
    @campgroundReview = new CampgroundReview {@auth, @exoid, proxy}

    # places
    @amenity = new Amenity {@auth}
    @campground = new Campground {@auth}

    @product = new Product {@auth}
    @pushToken = new PushToken {@auth, pushToken}
    @time = new Time({@auth})
    @drawer = new Drawer()
    @signInDialog = new SignInDialog()
    @getAppDialog = new GetAppDialog()
    @installOverlay = new InstallOverlay()
    @pushNotificationSheet = new PushNotificationSheet()
    @portal?.setModels {
      @user, @modal, @installOverlay, @getAppDialog, @pushToken
    }
    @window = new Window {@cookie, @experiment, userAgent}

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
