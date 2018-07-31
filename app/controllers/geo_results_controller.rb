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

      start_row = 0
      start_text = params[:proccess_info][:start_row]

      if start_text != nil and start_text.to_i > 0
        start_row = start_text.to_i
      end

      address_col = 0
      address_text = params[:proccess_info][:address_col]

      if address_text != nil and address_text.to_i > 0
        address_col = address_text.to_i
      end

      lat_col = 0
      lat_text = params[:proccess_info][:lat_col]

      if lat_text != nil and lat_text.to_i > 0
        lat_col = lat_text.to_i
      end

      lon_col = 0
      lon_text = params[:proccess_info][:lon_col]

      if lon_text != nil and lon_text.to_i > 0
        lon_col = lon_text.to_i
      end


      #TODO; just looking at first column for now as a test
      #TODO; actualy geocode instead of puts
      @geo_result = GeoResult.find(params[:geo_result_id])
      #A semi hacky path to
      #active_storage_disk = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
      #path = active_storage_disk.send(:path_for, @geo_result.source.blob.key)

      #less hacky way to get path but still not best, may be best though
      path = ActiveStorage::Blob.service.send(:path_for, @geo_result.source.blob.key)

      if params[:commit] == "geocode" 

        bad_item = []

        if address_col < 1
          bad_item << "No address column selected"
        end
        if start_row < 1
          bad_item << "No start row entered"
        end 

        if bad_item.length > 0
          flash[:danger] = bad_item.to_sentence(last_word_connector: ", and ")
          redirect_to action: "show", id: @geo_result[:id]
          #redirect_to action: "show", id: params[igeo_result_id]
          
          return
        end

        excel_file = Roo::Spreadsheet.open(path, {:extension => "xlsx"})

        puts excel_file.info

        #so we get first sheet
        sheet = excel_file.sheet(0)
        #now we make a kml and feed all the data to it
        puts sheet

        kml = KMLFile.new
        folder = KML::Folder.new(:name => "data")

        for at in start_row..sheet.last_row+1
          #top left is 1,1 cell also works by y,x
          info = sheet.cell(at,address_col)
          result = Geocoder.search(info)

          if result != nil and result.first != nil
            #so the result is not nill we can add the coords and data

            puts "\nInfo for"
            puts info
            print result.first, result.first.coordinates
            folder.features << KML::Placemark.new(
              :name =>info,
              :geometry => KML::Point.new(:coordinates => {:lat => result.first.coordinates[0], :lng => result.first.coordinates[1]})
            )
            #attempt to not flood api
            sleep(0.05)

          end

        end

        kml.objects << folder

        #send the user the fresh KML
        #send_data kml.render, :filename => "cci_out.kml"

        #delete if we already have one
        if @geo_result.result.attached?
          @geo_result.result.purge
        end

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

        flash[:success] = "File geocoded"
      else
        #here we'll make the lat lon creation

        bad_item = []

        if address_col < 1
          bad_item << "No address column selected"
        end
        if start_row < 1
          bad_item << "No start row entered"
        end 

        if lat_col < 1
          bad_item << "No Latitude column selected"
        end

        if lon_col < 1
          bad_item << "No Longitude column selected"
        end

        if bad_item.length > 0
        
          flash[:danger] = bad_item.to_sentence(last_word_connector: ", and ")
          
          #redirect_to geo_record_path(@geo_result)
          redirect_to action: "show", id: @geo_result[:id]
          #render "show"
          return
        end

        kml = KMLFile.new
        folder = KML::Folder.new(:name => "data")

        excel_file = Roo::Spreadsheet.open(path, {:extension => "xlsx"})

        puts excel_file.info

        #so we get first sheet
        sheet = excel_file.sheet(0)
        #now we make a kml and feed all the data to it
        puts sheet

        for at in start_row..sheet.last_row+1
          #top left is 1,1 cell also works by y,x
          address = sheet.cell(at,address_col)
          lat = sheet.cell(at,lat_col)
          lon = sheet.cell(at,lon_col)

          folder.features << KML::Placemark.new(
            :name =>address,
            :geometry => KML::Point.new(:coordinates => {:lat => lat, :lng => lon})
          )
        end

        kml.objects << folder

        #send the user the fresh KML
        #send_data kml.render, :filename => "from_excel.kml"

        #delete if we already have one
        if @geo_result.result.attached?
          @geo_result.result.purge
        end

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

        puts "other hit"
        flash[:success] = "KML created"
      end

      redirect_to action: "show", id: @geo_result[:id]

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
  