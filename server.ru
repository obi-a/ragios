#config.ru
require 'rubygems'
require "bundler/setup"
dir = Pathname(__FILE__).dirname.expand_path

require dir + 'ragios_server'


run Sinatra::Application
