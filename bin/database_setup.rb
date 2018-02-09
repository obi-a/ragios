#!/usr/bin/env ruby
require 'leanback'

database = Leanback::Couchdb.new(
  address: ENV['RAGIOS_COUCHDB_ADDRESS'],
  port: ENV['RAGIOS_COUCHDB_PORT']
)

begin
  username = ENV['COUCHDB_ADMIN_USERNAME']
  password = ENV['COUCHDB_ADMIN_PASSWORD']

  if password && username
    database.set_config(
      "admins",
      username = username,
      password = "\"#{password}\""
    )
    puts "CouchDB Admin user successfully created"
  else
    puts "No CouchDB Admin user configured"
  end
rescue RestClient::Unauthorized => e
  puts "CouchDB Admin user already created"
end
