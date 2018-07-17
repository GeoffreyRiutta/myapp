class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class test_load
  include ActiveModel::Model

  attr_acccessor :id, :data
end
