require 'config'
require 'logger'
require 'rubygems'
require 'active_record'

current = $config['db']['current']

#ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection $config['db'][current]

