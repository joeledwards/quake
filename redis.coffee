require 'log-a-log'

Q = require 'q'
Redis = require 'ioredis'

redis = new Redis

sleep = (millis, value) ->
  d = Q.defer()
  resolver = -> d.resolve value
  setTimeout resolver, millis
  d.promise

Q(true)
.then ->
  redis.set 'test-key', 'test-value-1', 'PX', 1000, 'NX'
.then (result) ->
  if result == 'OK'
    console.log 'Looks good.'
  else
    console.log 'WAT?!'
  redis.set 'test-key',  'test-value-2', 'PX', 1000, 'NX'
.then (result) ->
  if result == 'OK'
    console.log 'SAY WAT?!'
  else
    console.log 'Yeah...we good.'
  redis.get 'test-key'
.then (result) ->
  if result == 'test-value-1'
    console.log 'That is correct'
  else
    console.log "False. Black bear! [#{result}]"
  sleep 1000, true
.then ->
  redis.get 'test-key'
.then (result) ->
  console.log "The followig should be undefined: #{result}"
.then ->
  redis.disconnect()
.catch (error) ->
  console.error "Error testing Redis: #{error}\n#{error.stack}"

