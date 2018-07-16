module.exports =
  static: './src/static/**/*'
  coffee: ['./*.coffee', './src/**/*.coffee', './test/**/*.coffee']
  cover: [
    './*.coffee'
    './src/**/*.coffee'
    '!./src/**/*.test.coffee'
    '!./src/**/test.coffee'
  ]
  unitTests: ['./src/**/test.coffee', './src/**/*.test.coffee']
  serverTests: './test/server/index.coffee'
  functionalTests: './test/functional/**/*.coffee'
  root: './src/root.coffee'
  sw: './src/service_worker.coffee'
  dist: './dist'
  build: './build'
  swBuild: './build/service_worker.js'
  manifest: [
    './dist/**/*'
    '!./dist/**/*.map'
    '!./dist/humans.txt'
    '!./dist/robots.txt'
    '!./dist/stats.json'
    '!./dist/manifest.html'
  ]
