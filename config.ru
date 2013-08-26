#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path
require dir + 'config'
require dir + 'lib/ragios/rest_server'

run App

require dir + 'initialize'


