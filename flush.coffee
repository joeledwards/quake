require 'log-a-log'

Q = require 'q'
_ = require 'lodash'
Redis = require 'ioredis'

redis = new Redis

sleep = (millis, value) ->
  d = Q.defer()
  resolver = -> d.resolve value
  setTimeout resolver, millis
  d.promise

Q(true)
.then ->
  redis.keys 'quake::*'
.then (keys) ->
  count = _(keys).size()
  if count > 0
    console.log "#{count} quakes on record; deleting..."
    redis.del keys
  else
    console.log "No quake records found."
    false
.then (count) ->
  if count
    console.log "#{count} quake records deleted."
  redis.keys 'quake::*'
.then (keys) ->
  count = _(keys).size()
  console.log "#{count} quakes on record."
.then ->
  redis.disconnect()
.catch (error) ->
  console.error "Error testing Redis: #{error}\n#{error.stack}"

