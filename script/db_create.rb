#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '.')
require 'connection'

ActiveRecord::Schema.define do
  create_table   :companies, :force => true do |t|
    t.string     :permalink, :blog_feed, :homepage, :crunchbase, :description,
                 :limit => 256, :default => ''
    t.string     :twitter, :stock_symbol, :stock_market, :money_raised,
                 :category, :email, :limit => 64
    t.string     :blog, :limit => 512
    t.text       :overview, :aliases, :tags, :products, :default => ''
    t.integer    :employees, :default => 0
    t.date       :founded, :deadpooled
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
    t.references :other_company
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

