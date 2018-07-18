require 'rubygems'
require 'ruby_kml'
require 'geocoder'
require 'base64'
require 'stringio'

class VisitorsController < ApplicationController
    include KML

    #Test junk
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
    #end of test junk

    def cci_search()
        #Create kml file with entered location
        kml = KMLFile.new
        folder = KML::Folder.new(:name => "data")

        #the form is test_load. Data is the test_load text form
        result = Geocoder.search(params[:test_load][:data])

        #TODO; yell at user for null results
        
        #place the results into of the geocoding into the coords, also name it and
        #possilby put description data
        #TODO; Remove CCI hard coding
        folder.features << KML::Placemark.new(
            :name => "CCI",
            :geometry => KML::Point.new(:coordinates => {:lat=> result.first.coordinates[0],:lng=> result.first.coordinates[1]})
        )
        #folder is all the placemarks or other data, shove it into the objects 
        kml.objects << folder 
        #send the user the fresh KML
        send_data kml.render, :filename => "cci_out.kml"

        #create a new geo results

        result = GeoResult.create(search: params[:test_load][:data])
        
        #Welcome to the fun that is the attach. Attach wants a physical disk file
        #gotten through open method but we do not have that. we have a kml object
        #or the render output which is string. Neither have the read method that is
        #required for attachment.
        #so we force it into StringIO which acts like a file in ram and thus has
        #read
        fake_file = StringIO.new(kml.render)
        #TODO; give it better file name
        result.result.attach(io: fake_file, filename: "test.kml")
        #always close your fake files
        fake_file.close

        #result.save
    end

end
