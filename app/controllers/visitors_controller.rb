require 'rubygems'
require 'ruby_kml'

class VisitorsController < ApplicationController
    include KML

    def zero_island()
        #crate kml file, create zero 'island' pin and set it up for download
        kml = KMLFile.new
        folder = KML::Folder.new(:name => "Zero Island")
        [["Zero",0,0],].each do |name, lat, lng| folder.features << KML::Placemark.new(
            :name => name,
            :geometry => KML::Point.new(:coordinates => {:lat=>lat,:lng=>lng})
        )
        end
        kml.objects << folder
        send_data kml.render , :filename => "Out.kml"
        #send_file kml, :disposition=>"attachment; filename=test.kml"
    end
end
