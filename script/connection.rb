require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection YAML::load_file 'db.yaml'

