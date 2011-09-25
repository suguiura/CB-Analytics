#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '.')
require 'connection'

ActiveRecord::Schema.define do
  create_table   :companies, :force => true do |t|
    t.string     :permalink, :twitter, :blog, :blog_feed, :category,
                 :crunchbase, :homepage, :email, :stock_market, :stock_symbol
    t.text       :description, :overview, :aliases, :tags, :products
    t.integer    :employees, :money_raised
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

