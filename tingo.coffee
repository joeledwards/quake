require "log-a-log"

TingoDb = require('tingodb')().Db
os = require 'os'

home = os.homedir()
dbPath = "tingo-data"
config = {}
db = new TingoDb(dbPath, config)
coll = db.collection "test-docs"

doc =
  _id: "us20005b4s"
  name:
    fist: "Joel"
    last: "Edwards"
  pheon: "210.555.7600"

coll.insert doc, (error, result) ->
  if error?
    console.error "Error inserting document: #{error}\n#{error.stack}"
  else
    console.log JSON.stringify(result, null, 2)

