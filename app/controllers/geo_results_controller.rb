#Created by Geoffrey Riutta
require 'stringio'
require 'roo'
require 'rubygems'
require 'ruby_kml'
require 'geocoder'

#Controler will be responcable for basic create and attachment of kmls generated after an excel is
#attached. KML will not be generated upon creation user will have to request it after attaching 
#the excel and supplying the column to extract addresses from fo geocoding or lat/lon for pure geo
#kml creation
#TODO; lat/lon pure kml creation
#TODO; actual refrence file for data instead of first row tests
#TODO; validation of data


class GeoResultsController < ApplicationController
    def create
      #right now we are not doing just the search term

      @geo_result = GeoResult.new(geo_result_params)
      if @geo_result.save
        #GUD JOB
        #respond_with @geo_result
        puts "hi there"
        redirect_to @geo_result
      else
        flash[:error] = @geo_result.errors.full_messages
        render "new"
      end
  
    end

    def show

      @geo_result = GeoResult.find(params[:id])
    end

    def get_kml
      puts "!!!!!!!"
      puts params
      @geo_result =  GeoResult.find(params[:geo_result_id])
      kml = @geo_result.result
      send_data kml, :filename => "cci_out.kml"
    end

    def delete_result
      @geo_result = GeoResult.find(params[:geo_result_id])
      @geo_result.result.purge
      render "show"
    end

    def generate_kml
      #TODO; just looking at first column for now as a test
      #TODO; actualy geocode instead of puts
      @geo_result = GeoResult.find(params[:geo_result_id])
      #A semi hacky path to
      active_storage_disk = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
      path = active_storage_disk.send(:path_for, @geo_result.source.blob.key)

      puts "Look path\n\n"
      puts path

      excel_file = Roo::Spreadsheet.open(path, {:extension => "xlsx"})

      puts excel_file.info

      #so we get first sheet
      sheet = excel_file.sheet(0)
      #now we make a kml and feed all the data to it
      puts sheet

      kml = KMLFile.new
      folder = KML::Folder.new(:name => "data")

      for at in 0..sheet.last_row
        #top left is 1,1 cell also works by y,x
        info = sheet.cell(at+1,1)
        result = Geocoder.search(info)

        if result != nil and result.first != nil
          #so the result is not nill we can add the coords and data
          folder.features << KML::Placemark.new(
            :name =>info,
            :geometry => KML::Point.new(:coordinates => {:lat => result.first.coordinates[0], :lon => result.first.coordinates[1]})
          )

        end

      end

      kml.objects << folder

      #send the user the fresh KML
      send_data kml.render, :filename => "cci_out.kml"

      #Welcome to the fun that is the attach. Attach wants a physical disk file
      #gotten through open method but we do not have that. we have a kml object
      #or the render output which is string. Neither have the read method that is
      #required for attachment.
      #so we force it into StringIO which acts like a file in ram and thus has
      #read
      fake_file = StringIO.new(kml.render)
      #TODO; give it better file name
      @geo_result.result.attach(io: fake_file, filename: "test.kml")
      #always close your fake files
      fake_file.close

      #render "show"

    end

    def new
      @geo_result = GeoResult.new()
      
      
    end

    def destroy
      @geo_result = GeoResult.find(params[:id])
      @geo_result.destroy
      redirect_to geo_results_path
    end

    def index 
      #stuff for view to render
      @geo_results = GeoResult.all 
    end
    
    private
    def geo_result_params
        #just search, later we may be attaching the result data if fessiable with
        #activestorage
        params.require(:geo_result).permit(:search, :result, :source)
    end 
end
  