class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Test_load
  include ActiveModel::Model

  attr_accessor :id, :data
end
