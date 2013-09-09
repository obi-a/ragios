auth_session = Ragios::DatabaseAdmin.session
database_admin = Ragios::DatabaseAdmin.admin

#create the database if they don't already exist
begin
 Couchdb.create Ragios::DatabaseAdmin.monitors,auth_session

 data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
                  }

Couchdb.set_security(Ragios::DatabaseAdmin.monitors,data,auth_session)
rescue CouchdbException  => e
 #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
  
end

begin
 Couchdb.create Ragios::DatabaseAdmin.status_updates_settings,auth_session
 data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}
                  }
 Couchdb.set_security(Ragios::DatabaseAdmin.status_updates_settings,data,auth_session)
rescue CouchdbException 
   #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
end


begin
  Couchdb.create Ragios::DatabaseAdmin.activity_log,auth_session
  data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}}
  Couchdb.set_security(Ragios::DatabaseAdmin.activity_log,data,auth_session)
rescue CouchdbException  => e
  #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
end

begin
  Couchdb.create Ragios::DatabaseAdmin.auth_session,auth_session
  data = { :admins => {"names" => [database_admin[:username]], "roles" => ["admin"]},
                   :readers => {"names" => [database_admin[:username]],"roles"  => ["admin"]}}
  Couchdb.set_security(Ragios::DatabaseAdmin.auth_session,data,auth_session)
rescue CouchdbException  => e
  #raise error unless the database have already been creates
  raise e unless e.to_s == "CouchDB: Error - file_exists. Reason - The database could not be created, the file already exists."
end

Ragios::Server.init

#restart monitors from the database
begin
Ragios::Monitor.restart
rescue Ragios::MonitorNotFound
end

#run schedule any available status updates
begin
Ragios::Server.restart_status_updates
rescue RuntimeError
end
