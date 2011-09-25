#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '.')
require 'connection'
require 'models'

# auxiliary functions
def to_date(year, month, day)
  [year, ('0' + month.to_s)[-2..-1], ('0' + day.to_s)[-2..-1]].join('-')
end
def normalize(string)
  (string || '').gsub(/\\u([\da-fA-F]{4})/){|m|[$1].pack("H*").unpack("n*").pack("U*")}.dump[1..-2]
end
def parse_stock(string)
  (': ' + ((string || {})['stock_symbol'] || '')).split(':').last(2).map{|x|x.strip}
end
def create_offices(array)
  (array || []).map{|x| Office.new{|o| o.country_code = x['country_code']; o.latitude = x['latitude']; o.longitude = x['longitude']}}
end
def create_relationships(array, key)
  (array || []).map{|x| Relationship.new{|t| t.permalink = x[key]['permalink']; t.title = x['title']; t.past = x['is_past']}}
end
def create_transactions(array, date_prefix, quantity_prefix)
  d, q = date_prefix, quantity_prefix
  (array || []).map do |x|
    Transaction.new do |t|
      t.date = to_date(x["#{d}_year"], x["#{d}_month"], x["#{d}_day"])
      t.currency, t.value = x["#{q}_currency_code"], x["#{q}_amount"]
      t.company = Company.find_or_create_by_permalink((x['company'] || {})['permalink'])
    end
  end
end
#end of auxiliary functions

dir = '/tmp'
fy, fm, fd = 'founded_year', 'founded_month', 'founded_day'
dy, dm, dd = 'deadpooled_year', 'deadpooled_month', 'deadpooled_day'
array = YAML.load_file("#{dir}/companies.js").map{|c|c['permalink']}
array = ['facebook']
Company.find_or_create_by_permalink nil # creates the empty company
array.each_index do |i| permalink = array[i]
  $stderr.printf "\r%5d/%d", i, array.size
  data = YAML.load_file "#{dir}/companies/#{permalink}.js"
  company = Company.find_or_create_by_permalink(permalink) do |c|
    c.permalink    = data['permalink']
    c.created_at   = data['created_at']
    c.updated_at   = data['updated_at']
    c.employees    = data['number_of_employees']
    c.money_raised = data['total_money_raised']
    c.twitter      = data['twitter_username']
    c.blog         = data['blog_url']
    c.blog_feed    = data['blog_feed_url']
    c.category     = data['category_code']
    c.crunchbase   = data['crunchbase_url']
    c.homepage     = data['homepage_url']
    c.email        = data['email_address']
    c.description  = data['description']
    c.aliases      = data['alias_list']
    c.tags         = data['tag_list']
    c.overview     = normalize(data['overview'])
    c.founded      = to_date(data[fy], data[fm], data[fd])
    c.deadpooled   = to_date(data[dy], data[dm], data[dd])
    c.products     = (data['products'] || []).map{|x|x['permalink']}
    c.stock_market, c.stock_symbol = parse_stock(data['ipo'])
  end
  company.competitors = (data['competitions'] || []).map do |x|
    Company.find_or_create_by_permalink(x['competitor']['permalink'])
  end
  investments = (data['investments'] || []).map{|x|x['funding_round']}
  company.investments = create_transactions(investments, 'funded', 'raised')
  company.acquisitions = create_transactions(data['acquisitions'], 'acquired', 'price')
  company.funding_rounds = create_transactions(data['funding_rounds'], 'funded', 'raised')
  company.providerships = create_relationships(data['providerships'], 'provider')
  company.peopleships = create_relationships(data['relationships'], 'person')
  company.offices = create_offices(data['offices'])
  company.save
end

