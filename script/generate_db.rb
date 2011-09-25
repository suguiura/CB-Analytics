#!/usr/bin/env ruby

require 'yaml'
require 'logger'
require 'rubygems'
require 'active_record'

#dir = "/media/attach/crunchbase/data"
dir = '/tmp'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(:adapter => "sqlite3",
                                        :database => "#{dir}/crunchbase.sqlite3")
ActiveRecord::Schema.define do
  create_table   :companies, :force => true do |t|
    t.string     :permalink, :twitter, :blog, :blog_feed, :category,
                 :crunchbase, :homepage, :email, :stock_market, :stock_symbol
    t.text       :description, :overview, :aliases, :tags, :products
    t.integer    :employees, :money_raised
    t.date       :funded, :deadpooled
    t.timestamps
  end
  create_table   :competitions, :force => true, :id => false do |t|
    t.references :company, :competitor
  end
  create_table   :offices, :force => true do |t|
    t.references :company
    t.string     :country_code
    t.decimal    :latitude, :longitude, :precision => 9, :scale => 6
  end
  create_table   :transactions, :force => true do |t|
    t.references :company
    t.date       :date
    t.string     :value, :currency
  end
  create_table   :investments, :force => true, :id => false do |t|
    t.references :company, :transaction
  end
  create_table   :acquisitions, :force => true, :id => false do |t|
    t.references :company, :transaction
  end
  create_table   :funding_rounds, :force => true, :id => false do |t|
    t.references :company, :transaction
  end
  create_table   :relationships, :force => true do |t|
    t.string     :permalink, :title
    t.boolean    :past
  end
  create_table   :providerships, :force => true, :id => false do |t|
    t.references :company, :relationship
  end
  create_table   :peopleships, :force => true, :id => false do |t|
    t.references :company, :relationship
  end
end

class Company < ActiveRecord::Base
  has_and_belongs_to_many :competitors,
                          :class_name => 'Company',
                          :join_table => 'competitions',
                          :association_foreign_key => 'competitor_id'
  has_and_belongs_to_many :acquisitions,
                          :class_name => 'Transaction',
                          :join_table => 'acquisitions'
  has_and_belongs_to_many :investments,
                          :class_name => 'Transaction',
                          :join_table => 'investments'
  has_and_belongs_to_many :funding_rounds,
                          :class_name => 'Transaction',
                          :join_table => 'funding_rounds'
  has_and_belongs_to_many :providerships,
                          :class_name => 'Relationship',
                          :join_table => 'providerships'
  has_and_belongs_to_many :peopleships,
                          :class_name => 'Relationship',
                          :join_table => 'peopleships'
  has_many :offices
end
class Office < ActiveRecord::Base; belongs_to :company; end
class Transaction < ActiveRecord::Base; belongs_to :company; end
class Relationship < ActiveRecord::Base; end

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

fy, fm, fd = 'founded_year', 'founded_month', 'founded_day'
dy, dm, dd = 'deadpooled_year', 'deadpooled_month', 'deadpooled_day'
Company.find_or_create_by_permalink nil # creates the empty company
YAML.load_file("#{dir}/companies.js").map{|c|c['permalink']}.each do |permalink|
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
    c.funded       = to_date(data[fy], data[fm], data[fd])
    c.deadpooled   = to_date(data[dy], data[dm], data[dd])
    c.products     = (data['products'] || []).map{|x|x['permalink']}
    c.stock_market, c.stock_symbol = parse_stock(data['ipo'])
  end
  company.competitors = (data['competitions'] || []).map do |x|
    Company.find_or_create_by_permalink(x['competitor']['permalink'])
  end
  investments = data['investments'].map{|x|x['funding_round']}
  company.investments = create_transactions(investments, 'funded', 'raised')
  company.acquisitions = create_transactions(data['acquisitions'], 'acquired', 'price')
  company.funding_rounds = create_transactions(data['funding_rounds'], 'funded', 'raised')
  company.providerships = create_relationships(data['providerships'], 'provider')
  company.peopleships = create_relationships(data['relationships'], 'person')
  company.offices = create_offices(data['offices'])
  company.save
end

