# process.env.* is replaced at run-time with * environment variable
# Note that simply env.* is not replaced, and thus suitible for private config

_map = require 'lodash/map'
_range = require 'lodash/range'
_merge = require 'lodash/merge'
assertNoneMissing = require 'assert-none-missing'

colors = require './colors'

# Don't let server environment variables leak into client code
serverEnv = process.env

HOST = process.env.FREE_ROAM_HOST or '127.0.0.1'
HOSTNAME = HOST.split(':')[0]

URL_REGEX_STR = '(\\bhttps?://[-A-Z0-9+&@#/%?=~_|!:,.;]*[A-Z0-9+&@#/%=~_|])'
STICKER_REGEX_STR = '(:[a-z_]+:)'
IMAGE_REGEX_STR = '(\\!\\[(.*?)\\]\\((.*?)\\=([0-9.]+)x([0-9.]+)\\))'
IMAGE_REGEX_BASE_STR = '(\\!\\[(?:.*?)\\]\\((?:.*?)\\))'
LOCAL_IMAGE_REGEX_STR =
  '(\\!\\[(.*?)\\]\\(local://(.*?) \\=([0-9.]+)x([0-9.]+)\\))'
MENTION_REGEX_STR = '\\@[a-zA-Z0-9_-]+'
YOUTUBE_ID_REGEX_STR =
  '(?:youtube\\.com\\/(?:[^\\/]+\\/.+\\/|(?:v|e(?:mbed)?)\\/|.*[?&]v=)|youtu\\.be\\/)([^"&?\\/ ]{11})'

ONE_HOUR_SECONDS = 3600 * 1
TWO_HOURS_SECONDS = 3600 * 2
THREE_HOURS_SECONDS = 3600 * 3
FOUR_HOURS_SECONDS = 3600 * 4
EIGHT_HOURS_SECONDS = 3600 * 8
ONE_DAY_SECONDS = 3600 * 24 * 1
TWO_DAYS_SECONDS = 3600 * 24 * 2
THREE_DAYS_SECONDS = 3600 * 24 * 3

API_URL =
  serverEnv.BACK_ROADS_API_URL or # server
  process.env.PUBLIC_BACK_ROADS_API_URL # client

DEV_USE_HTTPS = process.env.DEV_USE_HTTPS and process.env.DEV_USE_HTTPS isnt '0'

isUrl = API_URL.indexOf('/') isnt -1
if isUrl
  API_HOST_ARRAY = API_URL.split('/')
  API_HOST = API_HOST_ARRAY[0] + '//' + API_HOST_ARRAY[2]
  API_PATH = API_URL.replace API_HOST, ''
else
  API_HOST = API_URL
  API_PATH = ''
# All keys must have values at run-time (value may be null)
isomorphic =
  LANGUAGES: ['en']
  # also in back-roads TODO: shared config file
  BASE_NAME_COLORS: ['#2196F3', '#8BC34A', '#FFC107', '#f44336']#, '#673AB7']

  # ALSO IN back-roads
  DEFAULT_PERMISSIONS:
    readMessage: true
    manageChannel: false
    sendMessage: true
    sendLink: true
    sendImage: true
  DEFAULT_NOTIFICATIONS:
    conversationMessage: true
    conversationMention: true
  CDN_URL: 'https://fdn.uno/d/images'
  # d folder has longer cache
  SCRIPTS_CDN_URL: 'https://fdn.uno/d/scripts'
  USER_CDN_URL: 'https://fdn.uno/images'
  DEFAULT_IOS_APP_ID: ''
  IOS_APP_URL: ''
  DEFAULT_GOOGLE_PLAY_APP_ID: ''
  GOOGLE_PLAY_APP_URL:
    ''
  HOST: HOST
  STRIPE_PUBLISHABLE_KEY:
    serverEnv.STRIPE_PUBLISHABLE_KEY or
    process.env.STRIPE_PUBLISHABLE_KEY
  GIPHY_API_KEY: process.env.GIPHY_API_KEY
  FB_ID: process.env.FREE_ROAM_FB_ID
  API_URL: API_URL
  PUBLIC_API_URL: process.env.PUBLIC_BACK_ROADS_API_URL
  API_HOST: API_HOST
  API_PATH: API_PATH
  VAPID_PUBLIC_KEY: process.env.BACK_ROADS_VAPID_PUBLIC_KEY
  # also in free-roam
  DEFAULT_PERMISSIONS:
    readMessage: true
    manageChannel: false
    sendMessage: true
    sendLink: true
    sendImage: true
  DEFAULT_NOTIFICATIONS:
    chatMessage: true
    chatMention: true
  FIREBASE:
    API_KEY: process.env.FIREBASE_API_KEY
    AUTH_DOMAIN: process.env.FIREBASE_AUTH_DOMAIN
    DATABASE_URL: process.env.FIREBASE_DATABASE_URL
    PROJECT_ID: process.env.FIREBASE_PROJECT_ID
    MESSAGING_SENDER_ID: process.env.FIREBASE_MESSAGING_SENDER_ID
  DEV_USE_HTTPS: DEV_USE_HTTPS
  AUTH_COOKIE: 'accessToken'
  ENV:
    serverEnv.NODE_ENV or
    process.env.NODE_ENV
  ENVS:
    DEV: 'development'
    PROD: 'production'
    TEST: 'test'

  PLAYER_COLORS: [
    colors.$amber500
    colors.$secondary500
    colors.$primary500
    colors.$green500
    colors.$red500
    colors.$blue500
  ]
  STICKER_REGEX_STR: STICKER_REGEX_STR
  STICKER_REGEX: new RegExp STICKER_REGEX_STR, 'g'
  URL_REGEX_STR: URL_REGEX_STR
  URL_REGEX: new RegExp URL_REGEX_STR, 'gi'
  LOCAL_IMAGE_REGEX_STR: LOCAL_IMAGE_REGEX_STR
  IMAGE_REGEX_BASE_STR: IMAGE_REGEX_BASE_STR
  IMAGE_REGEX_STR: IMAGE_REGEX_STR
  IMAGE_REGEX: new RegExp IMAGE_REGEX_STR, 'gi'
  MENTION_REGEX: new RegExp MENTION_REGEX_STR, 'gi'
  YOUTUBE_ID_REGEX: new RegExp YOUTUBE_ID_REGEX_STR, 'i'
  IMGUR_ID_REGEX: /https?:\/\/(?:i\.)?imgur\.com(?:\/a)?\/(.*?)(?:[\.#\/].*|$)/i

# Server only
# All keys must have values at run-time (value may be null)
PORT = serverEnv.FREE_ROAM_PORT or 3000
WEBPACK_DEV_PORT = serverEnv.WEBPACK_DEV_PORT or parseInt(PORT) + 1
WEBPACK_DEV_PROTOCOL = if DEV_USE_HTTPS then 'https://' else 'http://'

server =
  PORT: PORT

  # Development
  WEBPACK_DEV_PORT: WEBPACK_DEV_PORT
  WEBPACK_DEV_PROTOCOL: WEBPACK_DEV_PROTOCOL
  WEBPACK_DEV_URL: serverEnv.WEBPACK_DEV_URL or
    "#{WEBPACK_DEV_PROTOCOL}#{HOSTNAME}:#{WEBPACK_DEV_PORT}"
  SELENIUM_TARGET_URL: serverEnv.SELENIUM_TARGET_URL or null
  REMOTE_SELENIUM: serverEnv.REMOTE_SELENIUM is '1'
  SELENIUM_BROWSER: serverEnv.SELENIUM_BROWSER or 'chrome'
  SAUCE_USERNAME: serverEnv.SAUCE_USERNAME or null
  SAUCE_ACCESS_KEY: serverEnv.SAUCE_ACCESS_KEY or null

assertNoneMissing isomorphic
if window?
  module.exports = isomorphic
else
  assertNoneMissing server
  module.exports = _merge isomorphic, server
