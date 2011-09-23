#!/usr/bin/env ruby

require 'json'
require 'net/http'

host = 'api.crunchbase.com'

# download companies from http://api.crunchbase.com/v/1/companies.js
# parse the file
# download data from each company.


n = 0
JSON.parse(File.read('companies.js')).each do |company| x = company['permalink']
  $stderr.puts "#{x}"
  filename = "data/#{x}.js"
  next if File.exists? filename
  Process.fork do
    File.open(filename, 'w').write Net::HTTP.get(host, "/v/1/company/#{x}.js")
  end
#  j = JSON.parse Net::HTTP.get host, "/v/1/company/#{x['permalink']}.js"
#  puts x['permalink'] + ' ' + j['competitions'].map{|x|x['competitor']['permalink']}.join(' ')
  n += 1
#  sleep 1 if n % 5 == 0
  Process.waitall if n % 50 == 0
end
Process.waitall

