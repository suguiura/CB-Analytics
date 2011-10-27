require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'

config = YAML::load_file 'config.yaml'
current = config['db']['current']

#ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection config['db'][current]

