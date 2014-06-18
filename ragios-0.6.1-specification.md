#Ragios 0.6.1 Specification:

##Datastore
CouchDB Database: ragios_database

Documents:
```ruby
monitor = {
    monitor: "my website",
    every:  "5m",
    via: "twitter-notifier",
    plugin: "url-monitor",

    created_at_: "2014-04-16 01:52:40 +0000",
    creation_timestamp_: "1399215425",
    status_: "active",

    type: "monitor"
}
```
