
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

class Office < ActiveRecord::Base
  belongs_to :company
end

class Transaction < ActiveRecord::Base
  belongs_to :company
end

class Relationship < ActiveRecord::Base
end

