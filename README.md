###Ragios (Saint Ruby)

Ragios can be used to monitor any type of system including websites, servers, system services and web applications.

Sample usage to monitor a website for uptime in Ruby code:
<pre lang="ruby">
  monitor = {monitor: "My Website",
               url: "http://mysite.com",
               every: "5m",
               contact: "admin@mail.com",
               via: "email_notifier",
               plugin: "uptime_monitor"
             }

 ragios.add [monitor]
</pre>
The above example adds a monitor to Ragios, the monitor uses an "uptime_monitor" plugin to monitor the website "http://mysite.com" for uptime. This monitor runs tests on the website every 5 minutes, if it detects the website is down, it sends an  alert email to "admin@mail.com" via an email notifier.

##Features:
A small and minimal extensible design:
* Users can add, update, start, stop, restart and delete monitors in simple Ruby code. [See details](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)

* Plugins
  + Ragios relies on plugins to perform tests on different types of systems. The plugins are plain old ruby objects, any test that could be performed in ruby code could be performed by Ragios. Developers can create plugins to meet their specific needs.

* Notifications & Notifiers
  + Notifications are sent out when a test fails and when the test passes again
  + Notification messages are generated from ERB templates which developers can easily customize.
  + Multiple email addresses could be added to a monitor, so that when a test fails it notifies all the email addresses simultaneously.
  + Ragios relies on Notifiers to send out notifications. The notifiers are pluggable plain old ruby objects. Any type of notification that could be implemented in Ruby code can be sent by Ragios, notifications by email, SMS, twitter etc. Developers can create notifiers to meet their specific needs.
  + Ragios ships with a Gmail Notifier that sends notifications via gmail, Amazon SES notifier that sends notifications via Amazon Simple Email Service, and a twitter notifier that tweets notifications on twitter.
  + Multiple notifiers could be added to one monitor, so when a test fails it could send out  notifications via all the notifiers simultaneously. Example a monitor could be setup to send notifications via email, SMS and twitter simultaneously.

* REST API is available for interacting with Ragios via REST and JSON.

* Ragios includes a Ruby client library that makes it easy to interact with Ragios directly with ruby code.

* A Ragios instance running on a remote server and controlled it from anywhere using the Ruby client library or the REST API.


I'm doing this just for fun and educational purposes.

##Documentation:


* [Ragios (Saint Ruby)](http://www.whisperservers.com/ragios/ragios-saint-ruby/)

   + [Installation](http://www.whisperservers.com/ragios/ragios-saint-ruby/installation/)

   + [Setup](http://www.whisperservers.com/ragios/setup/)

   + [Start/Stop the server](http://www.whisperservers.com/ragios/running-ragios/)

   + [Using Ragios](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)

   + [Notifications](http://www.whisperservers.com/ragios/ragios-saint-ruby/notifications/)

   + [Creating Notifiers](http://www.whisperservers.com/ragios/notifiers/)

   + [Creating Plugins](http://www.whisperservers.com/ragios/plugins/)

   + [REST API](http://www.whisperservers.com/ragios/ragios-rest-api/)

     * [API Authentication](http://www.whisperservers.com/ragios/api-authentication/)

     * [Monitors API](http://www.whisperservers.com/ragios/monitors-api/)

   + [Analytics & Reporting](http://www.whisperservers.com/ragios/analytics-reporting/)

##License:
MIT License.

Copyright (c) 2014 Obi Akubue, obi-akubue.org
