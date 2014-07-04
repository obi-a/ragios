#Ragios 0.6.1 Specification:

##Datastore
CouchDB Database: ragios_database

Documents:
```ruby
require 'leanback'

ragios_db = Leanback::Couchdb.new(database: "ragios_database")

ragios_db.create

time  = Date.new(2014,06,21).to_time
timestamp = time.to_i

#monitor document
monitor = {
    monitor: "sweet website",
    every:  "5m",
    via: "twitter-notifier",
    plugin: "url-monitor",

    created_at_: time,
    creation_timestamp_: timestamp,
    status_: "active",

    type: "monitor"
}

ragios_db.create_doc  "monitor_2", monitor

#notification


#auth_session document
auth_session = {
   timeout: 900,
   timestamp: 1398528619
   type: auth_session
}


#test_result document
time = Time.new(2014,06,26,5,30,0, "-05:00")
timestamp = time.to_i
test_result = {
  monitor_id: "monitor_1",
  state: "failed",
  test_result: {winner: "chicken dinner"},
  time_of_test: time,
  timestamp_of_test: timestamp,
  monitor: {},
  type: "test_result"
}

ragios_db.create_doc  "activity#{timestamp}", test_result

#test_result design document
design_doc = {
 language: 'javascript',
 views: {
   results: {
     map: 'function(doc){ if(doc.type == "test_result" && doc.time_of_test && doc.monitor_id) emit([doc.monitor_id, doc.time_of_test]); }'
   }
 }
}
ragios_db.create_doc "_design/results", design_doc

#get the latest test result for monitor_1
monitor_1 = "monitor_1"
ragios_db.view("_design/results", "results",
      endkey: [monitor_1, "1913-01-15 05:30:00 -0500"].to_s,
      startkey: [monitor_1, "3015-01-15 05:30:00 -0500"].to_s,
      limit: 10,
      include_docs: true,
      descending: true)
#=> {:total_rows=>17,
# :offset=>0,
# :rows=>
#  [{:id=>"activity1403692200",
#    :key=>["monitor_1", "2014-06-25 05:30:00 -0500"],
#    :value=>nil,
#    :doc=>
#     {:_id=>"activity1403692200",
#      :_rev=>"1-b772d4ea8867faca9f9efb1ffdc33d2e",
#      :monitor_id=>"monitor_1",
#      :state=>"passed",
#      :test_result=>{:winner=>"chicken dinner"},
#      :time_of_test=>"2014-06-25 05:30:00 -0500",
#      :timestamp_of_test=>1403692200,
#      :monitor=>{},
#      :type=>"test_result"}}]}

#get state on a date
design_doc = {
 language: 'javascript',
 views: {
   monitor_state: {
     map: 'function(doc){ if(doc.type == "test_result" && doc.time_of_test && doc.monitor_id && doc.state) emit([doc.monitor_id, doc.state, doc.time_of_test]); }'
   }
 }
}
ragios_db.create_doc "_design/monitor_state", design_doc

#get monitor state by date
state = "failed"
monitor_1 = "monitor_1"
ragios_db.view("_design/monitor_state", "monitor_state",
      endkey: [monitor_1, state, "2014-06-25 05:30:00 -0500"].to_s,
      startkey: [monitor_1, state, "2014-06-26 05:30:00 -0500"].to_s,
      include_docs: true,
      descending: true)


state = "failed"
monitor_1 = "monitor_1"
ragios_db.view("_design/monitor_state", "monitor_state",
      endkey: [monitor_1, state, "2014-06-25"].to_s,
      startkey: [monitor_1, state, "2014-06-27"].to_s,
      include_docs: true,
      descending: true)


#get all failures
state = "failed"
monitor_1 = "monitor_1"
ragios_db.view("_design/monitor_state", "monitor_state",
      endkey: [monitor_1, state, "1914-06-25 05:30:00 -0500"].to_s,
      startkey: [monitor_1, state, "3014-06-26 05:30:00 -0500"].to_s,
      include_docs: true,
      descending: true)


get all passed tests
state = "passed"
monitor_1 = "monitor_1"
ragios_db.view("_design/monitor_state", "monitor_state",
      endkey: [monitor_1, state, "1914-06-25 05:30:00 -0500"].to_s,
      startkey: [monitor_1, state, "3014-06-26 05:30:00 -0500"].to_s,
      include_docs: true,
      descending: true)
```


##Ragios Admin
ragios client Object initilization request and receives an auth token, disconnect invalidates the auth token

```ruby
#ragios client

#initialization creates a connection
ragios = Ragios::Client.new(username: 'admin', password: 'password')
ragios.disconnect
```
##Failure tolerance
Removed failure tolerance


