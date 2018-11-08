Cache = require './cache'
Portal = require './portal'
Push = require './push'

push = new Push()
push.listen()

cache = new Cache()
cache.listen()

portal = new Portal {cache}
portal.listen()
