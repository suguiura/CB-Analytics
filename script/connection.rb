require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'

config = YAML::load_file 'db.yaml'
current = config['current']

#ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection config[current]

