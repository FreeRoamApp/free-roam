fs = require 'fs'
del = require 'del'
_defaults = require 'lodash/defaults'
_defaultsDeep = require 'lodash/defaultsDeep'
_map = require 'lodash/map'
_mapValues = require 'lodash/mapValues'
log = require 'loga'
gulp = require 'gulp'
gutil = require 'gulp-util'
webpack = require 'webpack'
autoprefixer = require 'autoprefixer'
manifest = require 'gulp-manifest'
spawn = require('child_process').spawn
coffeelint = require 'gulp-coffeelint'
webpackStream = require 'webpack-stream'
gulpSequence = require 'gulp-sequence'
WebpackDevServer = require 'webpack-dev-server'
HandleCSSLoader = require 'webpack-handle-css-loader'
UglifyJSPlugin = require 'uglifyjs-webpack-plugin'
MiniCssExtractPlugin = require 'mini-css-extract-plugin'
Visualizer = require('webpack-visualizer-plugin')
BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
s3Upload = require 'gulp-s3-upload'
argv = require('yargs').argv

config = require './src/config'
Language = require './src/lang'
paths = require './gulp_paths'

webpackBase =
  mode: 'development'
  module:
    exprContextRegExp: /$^/
    exprContextCritical: false
  resolve:
    extensions: ['.coffee', '.js', '.json']
  output:
    filename: 'bundle.js'
    publicPath: '/'

s3 = s3Upload {
  accessKeyId: process.env.RADIOACTIVE_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.RADIOACTIVE_AWS_SECRET_ACCESS_KEY
}

gulp.task 'dev', ['dev:webpack-server', 'watch:dev:server']
# TODO: 'dist:manifest' - appcache
gulp.task 'dist', gulpSequence(
  'dist:clean'
  ['dist:scripts', 'dist:static']
  'dist:concat'
  'dist:s3'
)

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['dev:server']

gulp.task 'watch:dev:server', ['dev:server'], ->
  gulp.watch paths.coffee, ['dev:server']

gulp.task 'lint', ->
  gulp.src paths.coffee
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task 'dev:server', ['build:static:dev'], do ->
  devServer = null
  process.on 'exit', -> devServer?.kill()
  ->
    devServer?.kill()
    devServer = spawn 'coffee', ['bin/dev_server.coffee'], {stdio: 'inherit'}
    devServer.on 'close', (code) ->
      if code is 8
        gulp.log 'Error detected, waiting for changes'

gulp.task 'dev:webpack-server', ->
  entries = [
    "webpack-dev-server/client?#{config.WEBPACK_DEV_URL}"
    'webpack/hot/dev-server'
    paths.root
  ]

  handleLoader = new HandleCSSLoader {
    minimize: false,
    extract: false,
    sourceMap: false,
    cssModules: false
    postcss: [
      autoprefixer {
        browsers: ['> 3% in US', 'last 2 firefox versions']
      }
    ]
  }

  compiler = webpack _defaultsDeep {
    devtool: 'inline-source-map'
    entry: entries
    output:
      path: __dirname
      publicPath: "#{config.WEBPACK_DEV_URL}/"
    module:
      rules: [
        {test: /\.coffee$/, loader: 'coffee-loader'}
        handleLoader.css()
        handleLoader.styl()
      ]
    plugins: [
      new webpack.HotModuleReplacementPlugin()
      # new webpack.IgnorePlugin /\.json$/, /lang/
      new webpack.DefinePlugin
        'process.env': _mapValues process.env, (val) -> JSON.stringify val
    ]
  }, webpackBase

  webpackOptions =
    publicPath: "#{config.WEBPACK_DEV_URL}/"
    hot: true
    headers: 'Access-Control-Allow-Origin': '*'
    noInfo: true
    disableHostCheck: true

  if config.DEV_USE_HTTPS
    console.log 'using https'
    webpackOptions.https = true
    webpackOptions.key = fs.readFileSync './bin/fr-dev.key'
    webpackOptions.cert = fs.readFileSync './bin/fr-dev.crt'

  new WebpackDevServer compiler, webpackOptions
  .listen config.WEBPACK_DEV_PORT, (err) ->
    if err
      log.error err
    else
      log.info
        event: 'webpack_server_start'
        message: "Webpack listening on port #{config.WEBPACK_DEV_PORT}"

gulp.task 'build:static:dev', ->
  gulp.src paths.static
    .pipe gulp.dest paths.build

gulp.task 'dist:clean', (cb) ->
  del paths.dist + '/*', cb

gulp.task 'dist:static', ['dist:clean'], ->
  gulp.src paths.static
    .pipe gulp.dest paths.dist

gulp.task 'dist:sw', ->
  gulp.src paths.sw
  .pipe webpackStream(_defaultsDeep({
    mode: 'production'
    optimization: {
      minimizer: [
        new UglifyJSPlugin {
          sourceMap: false
          uglifyOptions:
            mangle:
              reserved: ['process']
        }
      ]
    }
    module:
      rules: [
        {test: /\.coffee$/, loader: 'coffee-loader'}
      ]
    output:
      filename: 'service_worker.js'
    plugins: []
    resolve:
      extensions: ['.coffee', '.js', '.json']
  }, webpackBase), require('webpack'))
  .pipe gulp.dest paths.dist

gulp.task 'dist:scripts', ['dist:clean', 'dist:sw'], ->
  handleLoader = new HandleCSSLoader {
    minimize: true,
    extract: true,
    sourceMap: false,
    cssModules: false
    postcss: [
      autoprefixer {
        browsers: ['> 3% in US', 'last 2 firefox versions']
      }
    ]
  }
  _map config.LANGUAGES, (language) ->
    fs.writeFileSync(
      "#{__dirname}/#{paths.dist}/lang_#{language}.json"
      Language.getJsonString language
    )

  scriptsConfig = _defaultsDeep {
    mode: 'production'
    optimization: {
      minimizer: [
        new UglifyJSPlugin {
          sourceMap: false
          uglifyOptions:
            mangle:
              reserved: ['process']
        }
      ]
    }
    plugins: [
      new webpack.IgnorePlugin /\.json$/, /lang/
      new MiniCssExtractPlugin {
        filename: "bundle.css"
      }
    ]
    output:
      # TODO: '[hash].bundle.js' if we have caching issues, or use appcache
      filename: 'bundle.js'
    module:
      rules: [
        {test: /\.coffee$/, loader: 'coffee-loader'}
        handleLoader.css()
        handleLoader.styl()
      ]
  }, webpackBase

  gulp.src paths.root
  .pipe webpackStream scriptsConfig, require('webpack'), (err, stats) ->
    if err
      gutil.log err
      return
    statsJson = JSON.stringify {hash: stats.toJson().hash, time: Date.now()}
    fs.writeFileSync "#{__dirname}/#{paths.dist}/stats.json", statsJson
  .pipe gulp.dest paths.dist

gulp.task 'dist:concat', ->
  bundle = fs.readFileSync "#{__dirname}/#{paths.dist}/bundle.js", 'utf-8'
  matches = bundle.match(/process\.env\.[a-zA-Z0-9_]+/g)
  _map matches, (match) ->
    key = match.replace('process.env.', '')
    bundle = bundle.replace match, "'#{process.env[key]}'"
  stats = JSON.parse fs.readFileSync "#{__dirname}/#{paths.dist}/stats.json"
  _map config.LANGUAGES, (language) ->
    lang = fs.readFileSync(
      "#{__dirname}/#{paths.dist}/lang_#{language}.json", 'utf-8'
    )
    fs.writeFileSync(
      "#{__dirname}/#{paths.dist}/bundle_#{stats.hash}_#{language}.js"
      lang + bundle
    , 'utf-8')

gulp.task 'dist:s3', ->
  gulp.src("#{__dirname}/#{paths.dist}/bundle*")
  .pipe s3 {
    Bucket: 'fdn.uno'
    ACL: 'public-read'
    keyTransform: (relativeFilename) ->
      "d/scripts/#{relativeFilename}"
  }

gulp.task 'dist:manifest', ['dist:static', 'dist:scripts'], ->
  gulp.src paths.manifest
    .pipe manifest {
      hash: true
      timestamp: false
      preferOnline: true
      fallback: ['/ /offline.html']
    }
    .pipe gulp.dest paths.dist
