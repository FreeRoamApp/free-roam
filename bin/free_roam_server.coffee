#!/usr/bin/env coffee
_map = require 'lodash/map'
_range = require 'lodash/range'
cluster = require 'cluster'
os = require 'os'

app = require '../server'
config = require '../src/config'

if cluster.isMaster
  _map _range(os.cpus().length), ->
    cluster.fork()

  cluster.on 'exit', (worker) ->
    console.log
      event: 'cluster_respawn'
      message: "Worker #{worker.id} died, respawning"
    cluster.fork()
else
  app.listen config.PORT, ->
    console.log
      event: 'cluster_fork'
      message: "Worker #{cluster.worker.id}, listening on port #{config.PORT}"
