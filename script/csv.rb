#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '.')

require 'haversine'
require 'yaml'
require 'json'

header = []
header += %w(company founded deadpooled stock_market stock_symbol
             twitter_username blog_url blog_feed_url created_at updated_at
             category_code crunchbase_url homepage_url email_address description
             overview n_employees total_money_raised)
header += (1..20).each.map{|x|"alias[#{x}]"}
header += (1..50).each.map{|x|"tag[#{x}]"}
header += (1..100).each.map{|x|"products[#{x}]"}

def stats_office(company, competitor)
  a, b = (company['offices'] || []), (competitor['offices'] || [])
  results = a.map do |x|
    b.map do |y|
      lat1, lon1 = x['latitude'].to_f, x['longitude'].to_f
      lat2, lon2 = y['latitude'].to_f, y['longitude'].to_f
      haversine_distance(lat1, lon1, lat2, lon2)
      @distances['km']
    end
  end.flatten
  if results.size > 0
    [results.min, results.max, results.inject(:+) / results.size]
  else
    [0, 0, 0]
  end
end

header += (1..50).each.map do |x|
  ["competitor[#{x}]", "competitor[#{x}] tag similarity", "competitor[#{x}] has company", "competitor[#{x}] shortest office distance", "competitor[#{x}] longest office distance", "competitor[#{x}] mean office distance"]
end
def get_competitors(company, tags, competitors)
  (competitors.map do |competitor|
    cc = (competitor['competitions'] || []).map{|y|y['competitor']['permalink']}
    x = ((competitor['tag_list'] || '').split(',') & tags).size
    similarity = (x == 0 ? 0 : x / tags.size.to_f)
    [competitor['permalink'], similarity, cc.include?(company['permalink']), stats_office(company, competitor)]
  end + [[nil] * 3] * 50)[0, 50]
end

header += (1..400).each.map do |x|
  ["relationship[#{x}]", "relationship[#{x}] person", "relationship[#{x}] is past"]
end
def get_relationships(company)
  ((company['relationships'] || []).map do |x|
    [x['title'], x['person']['permalink'], x['is_past']]
  end + [[nil] * 3] * 400)[0, 400]
end

header += (1..50).each.map do |x|
  ["providership[#{x}]", "providership[#{x}] provider", "providership[#{x}] is past"]
end
def get_providerships(company)
  ((company['providerships'] || []).map do |x|
    [x['title'], x['provider']['permalink'], x['is_past']]
  end + [[nil] * 3] * 50)[0, 50]
end

header += (1..20).each.map do |x|
  ["funding_round[#{x}] date", "funding_round[#{x}] amount", "funding_round[#{x}] currency"]
end
def get_funding_rounds(company)
  ((company['funding_rounds'] || []).map do |x|
    year = x['founded_year']
    month = ('0' + x['founded_month'].to_s)[-2..-1]
    day = ('0' + x['founded_day'].to_s)[-2..-1]
    value = x['raised_amount']
    currency = x['raised_currency_code']
    [[year, month, day].join('-'), value, currency]
  end + [[nil] * 3] * 20)[0, 20]
end

header += (1..150).each.map do |x|
  ["acquisition[#{x}] date", "acquisition[#{x}] amount", "acquisition[#{x}] currency", "acquisition[#{x}] company"]
end
def get_acquisitions(company)
  ((company['acquisitions'] || []).map do |x|
    year = x['acquired_year']
    month = ('0' + x['acquired_month'].to_s)[-2..-1]
    day = ('0' + x['acquired_day'].to_s)[-2..-1]
    value = x['price_amount']
    currency = x['price_currency_code']
    company = x['company']['permalink']
    [[year, month, day].join('-'), value, currency, company]
  end + [[nil] * 4] * 150)[0, 150]
end

header += (1..150).each.map do |x|
  ["investment[#{x}] date", "investment[#{x}] amount", "investment[#{x}] currency", "investment[#{x}] company"]
end
def get_investments(company)
  ((company['investments'] || []).map do |y| x = y['funding_round']
    year = x['funded_year']
    month = ('0' + x['funded_month'].to_s)[-2..-1]
    day = ('0' + x['funded_day'].to_s)[-2..-1]
    value = x['raised_amount']
    currency = x['raised_currency_code']
    company = x['company']['permalink']
    [[year, month, day].join('-'), value, currency, company]
  end + [[nil] * 4] * 150)[0, 150]
end

header += (1..100).each.map do |x|
  ["office[#{x}] country", "office[#{x}] lat", "office[#{x}] long"]
end
def get_offices(company)
  ((company['offices'] || []).map do |x|
    [x['country_code'], x['latitude'], x['longitude']]
  end + [[nil] * 3] * 100)[0, 100]
end

puts header.join("\t")

def load_company(permalink)
  YAML.load_file "data/companies/#{permalink}.js"
end

def load_competitors(company)
  (company['competitions'] || []).map{|x|load_company(x['competitor']['permalink'])}
end

all = YAML.load_file('data/companies.js').map{|c|c['permalink']}
n = half = all.size
all.each do |permalink| n -= 1
  (STDERR.printf("%d", half); half /= 2) if n <= half
#  next unless permalink == 'google'
  company = load_company permalink
  competitors = load_competitors(company)
  aliases = (company['alias_list'] || '').split(',')
  tags = (company['tag_list'] || '').split(',')
  products = (company['products'] || []).map{|x|x['permalink']}
  stock = (': ' + ((company['ipo'] || {})['stock_symbol'] || '')).split(':').last(2).map{|x|x.strip}
  puts [permalink,
        [company['founded_year'],
         ('0' + company['founded_month'].to_s)[-2..-1],
         ('0' + company['founded_day'].to_s)[-2..-1]].join('-'),
        [company['deadpooled_year'],
         ('0' + company['deadpooled_month'].to_s)[-2..-1],
         ('0' + company['deadpooled_day'].to_s)[-2..-1]].join('-'),
        stock,
        company['twitter_username'],
        company['blog_url'],
        company['blog_feed_url'],
        company['created_at'],
        company['updated_at'],
        company['category_code'],
        company['crunchbase_url'],
        company['homepage_url'],
        company['email_address'],
        company['description'],
        (company['overview'] || '').gsub(/\\u([\da-fA-F]{4})/){|m| [$1].pack("H*").unpack("n*").pack("U*")}.dump[1..-2],
        company['number_of_employees'] || 0,
        company['total_money_raised'] || '',
        (aliases + [nil] * 20)[0, 20],
        (tags + [nil] * 50)[0, 50],
        (products + [nil] * 100)[0, 100],
        get_competitors(company, tags, competitors),
        get_relationships(company),
        get_providerships(company),
        get_funding_rounds(company),
        get_acquisitions(company),
        get_investments(company),
        get_offices(company)
       ].join("\t")
end

