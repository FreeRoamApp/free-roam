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
TerserPlugin = require 'terser-webpack-plugin'
MiniCssExtractPlugin = require 'mini-css-extract-plugin'
Visualizer = require('webpack-visualizer-plugin')
# BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
gcPub = require 'gulp-gcloud-publish'
gzip = require 'gulp-gzip'
sizereport = require 'gulp-sizereport'
argv = require('yargs').argv
SpeedMeasurePlugin = require 'speed-measure-webpack-plugin'
HardSourceWebpackPlugin = require 'hard-source-webpack-plugin'

smp = new SpeedMeasurePlugin();

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

gulp.task 'dev', ['dev:webpack-server', 'watch:dev:server']

gulp.task 'dist', gulpSequence(
  'dist:clean'
  ['dist:scripts', 'dist:static']
  'dist:concat'
  'dist:sw'
  'dist:gc'
  'dist:sizereport'
)

gulp.task 'dist:sw', gulpSequence(
  'dist:sw:script'
  'dist:sw:replace'
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
      pathinfo: false # seems to improve perf
    module:
      rules: [
        {test: /\.coffee$/, loader: 'coffee-loader'}
        handleLoader.css()
        handleLoader.styl()
      ]
    plugins: [
      new webpack.HotModuleReplacementPlugin()
      # new webpack.IgnorePlugin /\.json$/, /lang/
      # new HardSourceWebpackPlugin()
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

gulp.task 'dist:sw:script', ->
  gulp.src paths.sw
  .pipe webpackStream(_defaultsDeep({
    mode: 'production'
    optimization: {
      minimizer: [
        new TerserPlugin {
          parallel: true
          terserOptions:
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

gulp.task 'dist:sw:replace', ->
  stats = JSON.parse fs.readFileSync "#{__dirname}/#{paths.dist}/stats.json"
  sw = fs.readFileSync "#{__dirname}/#{paths.dist}/service_worker.js", 'utf-8'
  sw = sw.replace /\|HASH\|/g, stats.hash
  fs.writeFileSync("#{__dirname}/#{paths.dist}/service_worker.js", sw, 'utf-8')

gulp.task 'dist:scripts', ['dist:clean'], ->
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
    # not sure which module is doing it, but the node buffer module is being
    # pulled in. can disable with this
    # https://github.com/webpack/webpack/issues/4240
    node:
      Buffer: false
      # process: false
    optimization: {
      # minimize: false
      minimizer: [
        new TerserPlugin {
          parallel: true
          terserOptions:
            # ecma: 6
            ie8: false
            mangle:
              reserved: ['process']
        }
      ]
    }
    plugins: [
      new Visualizer()
      # new BundleAnalyzerPlugin()
      new webpack.IgnorePlugin /\.json$/, /lang/
      new MiniCssExtractPlugin {
        filename: 'bundle.css'
      }
      ->
        this.plugin 'done', (stats) ->
          if stats.compilation.errors and stats.compilation.errors.length
            console.log stats.compilation.errors
            process.exit 1
    ]
    # remark requires this (parse-entities -> character-entities)
    # character-entities is 38kb and not really necessary. legacy is 1.64kb
    resolve:
      alias:
       'character-entities': 'character-entities-legacy'
    output:
      # TODO: '[hash].bundle.js' if we have caching issues, or use appcache
      filename: 'bundle.js'
      chunkFilename: '[name]_bundle_[hash].js',
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
  stats = JSON.parse fs.readFileSync "#{__dirname}/#{paths.dist}/stats.json"

  fs.renameSync(
    "#{__dirname}/#{paths.dist}/bundle.css"
    "#{__dirname}/#{paths.dist}/bundle_#{stats.hash}.css"
  )

  bundle = fs.readFileSync "#{__dirname}/#{paths.dist}/bundle.js", 'utf-8'
  bundle = bundle.replace /\|HASH\|/g, stats.hash
  matches = bundle.match(/process\.env\.[a-zA-Z0-9_]+/g)
  _map matches, (match) ->
    key = match.replace('process.env.', '')
    bundle = bundle.replace match, "'#{process.env[key]}'"
  _map config.LANGUAGES, (language) ->
    lang = fs.readFileSync(
      "#{__dirname}/#{paths.dist}/lang_#{language}.json", 'utf-8'
    )
    fs.writeFileSync(
      "#{__dirname}/#{paths.dist}/bundle_#{stats.hash}_#{language}.js"
      lang + bundle
    , 'utf-8')

gulp.task 'dist:gc', ->
  gulp.src("#{__dirname}/#{paths.dist}/*bundle*")
  .pipe gzip()
  .pipe gcPub {
    bucket: 'fdn.uno'
    keyFilename: '../padlock/free-roam-google-cloud-storage-creds.json'
    projectId: 'free-roam-app'
    base: '/d/scripts'
    public: true
    transformDestination: (path) ->
      return path
    metadata:
      cacheControl: 'max-age=315360000, no-transform, public'
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

gulp.task 'dist:sizereport', ->
  gulp.src "#{__dirname}/#{paths.dist}/bundle*"
  .pipe sizereport()
