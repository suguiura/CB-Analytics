#!/usr/bin/env ruby

require 'yaml'
require 'net/http'

# download companies from http://api.crunchbase.com/v/1/companies.js
host = 'api.crunchbase.com'
n = 0
YAML::load_file('companies.js').each do |company| x = company['permalink']
  $stderr.puts "#{x}"
  filename = "data/#{x}.js"
  next if File.exists? filename
  Process.fork do
    File.open(filename, 'w').write Net::HTTP.get(host, "/v/1/company/#{x}.js")
  end
  n += 1
  Process.waitall if n % 50 == 0
end
Process.waitall

