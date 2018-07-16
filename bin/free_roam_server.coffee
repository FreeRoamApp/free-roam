#!/usr/bin/env coffee
_map = require 'lodash/map'
_range = require 'lodash/range'
log = require 'loga'
cluster = require 'cluster'
os = require 'os'

app = require '../server'
config = require '../src/config'

if cluster.isMaster
  _map _range(os.cpus().length), ->
    cluster.fork()

  cluster.on 'exit', (worker) ->
    log.warn
      event: 'cluster_respawn'
      message: "Worker #{worker.id} died, respawning"
    cluster.fork()
else
  app.listen config.PORT, ->
    log.info
      event: 'cluster_fork'
      message: "Worker #{cluster.worker.id}, listening on port #{config.PORT}"
