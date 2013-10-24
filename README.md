###Ragios (Saint Ruby) 

>I imagine that Ragios cant be in harmony with the present moment because it has a goal. It wants to become a monitoring system. Maybe once it has reached maturity it will live in harmony with the present moment. Ragios doesnt want anything because it is at one with the totality. And the totality acts thru it.

>We could say that the totality, life, wants Ragios to become a monitoring system but Ragios doesnt see itself as separate from life, and so wants nothing for itself, it is one with what life wants, thats why it isnt worried or stressed. And if has to die premaurely it dies with  ease.


While reading the book “Nagios: system and Network Monitoring” by Wolfgang Barth, I thought it will be a good idea to write a Ruby based System Monitoring tool similar to Nagios. 

So I started writing such a tool. Since it was inspired by Nagios, I will call it Ragios (Ruby Agios) aka Saint Ruby since Agios is Saint in Greek.

This is all just for fun and educational purposes. Ruby makes programmers more productive, a longterm goal of this project is to make system monitoring fun and more productive.

Ragios could be used to monitor any type of system including servers, workstations, switches, routers, system services and applications, locally or over a network. The system admin can define the tests he wants to run on the system or re-use tests written by other developers. The tests run periodically on the system. When a test fails the admin receives an email or SMS alert.

(Update 10-20-13:) master branch is v0.6.0, which is a complete rewrite, the documentation below is v0.5.1 currently on the release branch. v0.6.0 is not yet documented. See [Changelog](https://github.com/obi-a/Ragios/blob/master/Changelog.rdoc) for details on v0.6.0 rolling release. 

* [Ragios (Saint Ruby)](http://www.whisperservers.com/ragios/ragios-saint-ruby/)

   + [Installation](http://www.whisperservers.com/ragios/ragios-saint-ruby/installation/)
   
   + [Using Ragios](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)
   
   + [Notifications](http://www.whisperservers.com/ragios/ragios-saint-ruby/notifications/)
   
   + [Status Reports](http://www.whisperservers.com/ragios/ragios-saint-ruby/status-reports/)
   
   + [Failure Recovery](http://www.whisperservers.com/ragios/ragios-saint-ruby/adding-failure-recovery-code-to-monitors/) 
   
* [Ragios Plugin System](http://www.whisperservers.com/ragios/ragios-plugin-system/)

* [Ragios Server](http://www.whisperservers.com/ragios/ragios-server/)

   + [Server Setup](http://www.whisperservers.com/ragios/server-setup/)
   
   + [Using Ragios Server](http://www.whisperservers.com/ragios/usage/)
   
   + [REST API](http://www.whisperservers.com/ragios/ragios-rest-api/)

     * [API Authentication](http://www.whisperservers.com/ragios/api-authentication/) 
   
     * [Monitors API](http://www.whisperservers.com/ragios/monitors-api/) 
     
     * [Status Updates API](http://www.whisperservers.com/ragios/status-updates-api/) 
    
