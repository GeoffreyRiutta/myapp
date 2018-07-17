require 'rubygems'
require 'ruby_kml'
require 'geocoder'

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

    def cci_loc()
        #Create kml file with cci location
        kml = KMLFile.new
        folder = KML::Folder.new(:name => "CCI Location")

        result = Geocoder.search("CCI Systems Iron Mountain Michigan")
        folder.features << KML::Placemark.new(
            :name => "CCI",
            :geometry => KML::Point.new(:coordinates => {:lat=> result.first.coordinates[0],:lng=> result.first.coordinates[1]})
        )

        kml.objects << folder 
        send_data kml.render, :filename => "cci_out.kml"

    end

    def cci_search()
        #Create kml file with entered location
        kml = KMLFile.new
        folder = KML::Folder.new(:name => "data")

        puts "???"
        puts params
        puts "!!!"

        result = Geocoder.search(params[:test_load][:data])
        folder.features << KML::Placemark.new(
            :name => "CCI",
            :geometry => KML::Point.new(:coordinates => {:lat=> result.first.coordinates[0],:lng=> result.first.coordinates[1]})
        )

        kml.objects << folder 
        send_data kml.render, :filename => "cci_out.kml"
    end

end
