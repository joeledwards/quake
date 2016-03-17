#!/usr/bin/env coffee

require 'log-a-log'

Q = require 'q'
_ = require 'lodash'
moment = require 'moment'
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

getQuakes()
.then (geo) ->
  console.log "Got the JSON:"
  console.log JSON.stringify(geo.data, null, 2)
  console.log "#{_(geo.data.features).size()} features."
  console.log "Fetch took #{geo.requestDuration}; parsing took #{geo.parseDuration}"
.catch (error) ->
  console.error "Error fetching Geo JSON: #{error}\n#{error.stack}"

