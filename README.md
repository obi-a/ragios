# Ragios (Saint Ruby)

[![Build Status](https://travis-ci.org/obi-a/ragios.svg?branch=master)](https://travis-ci.org/obi-a/ragios)

Ragios can be used to monitor any type of system including websites, servers, system services and web applications.

Sample usage to monitor a website for uptime in Ruby code:
```ruby
monitor = {
  monitor: "My Website",
  url: "http://mysite.com",
  every: "5m",
  contact: "admin@mail.com",
  via: "email_notifier",
  plugin: "uptime_monitor"
}

ragios.create(monitor)
```
The above example creates a monitor that monitor uses an `uptime_monitor` plugin to monitor the website `http://mysite.com` for uptime. This monitor runs tests on the website every 5 minutes, if it detects the website is down, it sends an  alert email to `admin@mail.com` via an email notifier.

## Features:
A small and minimal extensible design:
* Users can add, update, start, stop, restart and delete monitors that can monitor anything in simple Ruby code. [See details](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)

* Includes a REST API, a web admin dashboard (Web UI) and a Ruby client rubygem that makes it easy to interact with Ragios directly with ruby code.

* Ragios is re-designed & re-written to be modular, memory efficient, distributed, and scalable.

* Ragios runs as a set of tiny distributed microservices, communicating with each other via ZeroMQ, and packaged with docker-compose.

* Only dependency required to run Ragios is docker-compose.

* Plugins
  + Ragios relies on plugins to perform tests on different types of systems. The plugins are plain old ruby objects, any test/check that could be performed in ruby code could be performed by Ragios. Developers can create plugins to meet their specific needs.
  + Ragios ships with a built-in url_monitor plugin for monitoring http(s) endpoints for uptime, developers can implement other types of plugins.

* Notifications & Notifiers
  + Notifications are sent out when a test fails and when the test passes again.
  + Notification messages are generated from ERB templates which developers can easily customize.
  + Multiple email addresses could be added to a monitor, so it notfies all email addresses when a test fails or recovers from failure.
  + Ragios relies on Notifiers to send out notifications. The notifiers are pluggable plain old ruby objects. Any type of notification that could be implemented in Ruby code can be sent by Ragios, notifications by email, SMS, Slack etc. Developers can create notifiers to meet their specific needs.
  + Ragios ships with a built-in Amazon SES notifier that sends notifications via Amazon SES, developers can implement other types of notifiers.
  + Multiple notifiers could be added to one monitor, so when a test fails or recovers from failure, it ssends out notifications via all the notifiers. For example a monitor could be setup to send notifications via email, SMS, Slack and twitter simultaneously.


I'm doing this just for fun and educational purposes.

## Documentation:


* [Ragios (Saint Ruby)](http://www.whisperservers.com/ragios/ragios-saint-ruby/)

   + [Installation](http://www.whisperservers.com/ragios/ragios-saint-ruby/installation/)

   + [Start/Stop the server](http://www.whisperservers.com/ragios/running-ragios/)

   + [Using Ragios](http://www.whisperservers.com/ragios/ragios-saint-ruby/using-ragios/)

   + [Notifications](http://www.whisperservers.com/ragios/ragios-saint-ruby/notifications/)

   + [Events](http://www.whisperservers.com/ragios/events/)

   + [Services](http://www.whisperservers.com/ragios/services/)

   + [Web Admin Dashboard](https://github.com/obi-a/ragios/wiki/Web-Admin-Dashboard)

   + [Development Mode](http://www.whisperservers.com/ragios/development-mode/)

   + [Creating Notifiers](http://www.whisperservers.com/ragios/notifiers/)

   + [Creating Plugins](http://www.whisperservers.com/ragios/plugins/)

   + [Authentication](http://www.whisperservers.com/ragios/authentication/)

   + [REST API](http://www.whisperservers.com/ragios/ragios-rest-api/)

     * [API Authentication](http://www.whisperservers.com/ragios/api-authentication/)

     * [Monitors API](http://www.whisperservers.com/ragios/monitors-api/)

     * [Events API](http://www.whisperservers.com/ragios/events-api/)


## License:
MIT License.

Copyright (c) 2018 Obi Akubue, obi-akubue.org
