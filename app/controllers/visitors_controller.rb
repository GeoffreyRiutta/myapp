require 'rubygems'
require 'ruby_kml'
require 'geocoder'
require 'base64'
require 'stringio'

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
        puts result

        folder.features << KML::Placemark.new(
            :name => "CCI",
            :geometry => KML::Point.new(:coordinates => {:lat=> result.first.coordinates[0],:lng=> result.first.coordinates[1]})
        )

        kml.objects << folder 
        send_data kml.render, :filename => "cci_out.kml"

        #create a new geo results
        #encoding because won't accept straight objects or strings
        #convert = Base64.encode64(kml.render)
        result = GeoResult.create(search: params[:test_load][:data])

        fake_file = StringIO.new(kml.render)

        puts "pre silence"
        puts result.result.attached?
        puts "lambs"
        
        result.result.attach(io: fake_file, filename: "test.kml")

        fake_file.close

        puts "the lotion on its skin"
        puts result.result.attached?
        puts "or else it gets attached again"
        #result.save
    end

end
