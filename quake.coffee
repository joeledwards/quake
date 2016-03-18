#!/usr/bin/env coffee

require 'log-a-log'

Q = require 'q'
_ = require 'lodash'
moment = require 'moment'
Redis = require 'ioredis'
request = require 'request'
durations = require 'durations'

baseUrl = 'http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary'

hour45 = "#{baseUrl}/4.5_hour.geojson"
day45 = "#{baseUrl}/4.5_day.geojson"
week45 = "#{baseUrl}/4.5_week.geojson"
month45 = "#{baseUrl}/4.5_month.geojson"

hour25 = "#{baseUrl}/2.5_hour.geojson"
day25 = "#{baseUrl}/2.5_day.geojson"
week25 = "#{baseUrl}/2.5_week.geojson"
month25 = "#{baseUrl}/2.5_month.geojson"

hour10 = "#{baseUrl}/1.0_hour.geojson"
day10 = "#{baseUrl}/1.0_day.geojson"
week10 = "#{baseUrl}/1.0_week.geojson"
month10 = "#{baseUrl}/1.0_month.geojson"

hourAll = "#{baseUrl}/all_hour.geojson"
dayAll = "#{baseUrl}/all_day.geojson"
weekAll = "#{baseUrl}/all_week.geojson"
monthAll = "#{baseUrl}/all_month.geojson"

url = month45
expiration = 24 * 60 * 60 * 1000

redis = new Redis()

# Attempt to add a quake to the database
addQuake = (quake) ->
  {id, properties: {mag, time, tz}, geometry: {coordinates: [longitude, latitude, depth]}} = quake

  now = moment.utc()
  timestamp = moment(time)
  expire = expiration - (now.valueOf() - timestamp.valueOf())

  key = "quake::#{id}"

  if expire < 0
    #console.log "Expire for #{key} is #{expire}"
    Q(undefined)
  else 
    Q(true)
    .then ->
      redis.set key, JSON.stringify(quake), 'PX', expire, 'NX'
      .then (result) ->
        if result == "OK"
          console.log "New quake added [#{id}] magnitude #{mag} (#{longitude}, #{latitude}, #{depth} km)"
          quake
        else
          undefined


# Fetch the latest quakes
getQuakes = ->
  d = Q.defer()
  requestWatch = durations.stopwatch().start()

  request.get url, (error, response, body) ->
    requestWatch.stop()

    if error?
      d.reject error
    else if response.statusCode != 200
      d.reject new Error("Request failed with status [#{response.statusCode}]")
    else
      try
        
        parseWatch = durations.stopwatch().start()
        geo = JSON.parse body
        parseWatch.stop()

        #console.log "Fetch took #{requestWatch}; parsing took #{parseWatch}"

        d.resolve
          data: geo
          requestDuration: requestWatch.duration()
          parseDuration: parseWatch.duration()
      catch error
        d.reject error
  d.promise


# Fetch quakes
getQuakes()

# Process the results
.then (geo) ->
  console.log "Got the JSON:"
  #console.log JSON.stringify(geo.data, null, 2)
  console.log "#{_(geo.data.features).size()} features."
  console.log "Fetch took #{geo.requestDuration}; parsing took #{geo.parseDuration}"

  quakes = _(geo.data.features)

  newQuakes = 0
  oldQuakes = 0
  ps = quakes
    .map (quake) ->
      addQuake quake
      .then (newQuake) ->
        if newQuake?
          #console.log "Send alert for #{newQuake.id} (magnitude #{newQuake.properties.mag}."
          newQuakes += 1
        else
          #console.log "#{quake.id} (magnitude #{quake.properties.mag}) is old news."
          oldQuakes += 1
      .then ->
        true
    .value()

  Q.all ps
  .then ->
    geo: geo
    newQuakes: newQuakes
    oldQuakes: oldQuakes

.then ({geo, newQuakes, oldQuakes}) ->
  console.log "Fetch took #{geo.requestDuration}; parsing took #{geo.parseDuration}"
  console.log "#{_(geo.data.features).size()} features (#{oldQuakes} old, #{newQuakes} new)."
  console.log "All done."
  redis.disconnect()

.catch (error) ->
  console.error "Error fetching Geo JSON: #{error}\n#{error.stack}"

