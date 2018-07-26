class GeoResult < ApplicationRecord

    has_one_attached :source
    has_one_attached :result
    

    validates_presence_of :search

end
