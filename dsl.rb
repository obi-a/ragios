  #Using a DSL for Ragios
  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  
  dir = Pathname(__FILE__).dirname.expand_path
  require dir + 'lib/ragios'
    




