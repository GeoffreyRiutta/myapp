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
      redirect_to action: "show", id: @geo_result[:id]
    end

    def generate_kml

      #figuring out what the user entered
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


      @geo_result = GeoResult.find(params[:geo_result_id])
      #A semi hacky path to
      #active_storage_disk = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
      #path = active_storage_disk.send(:path_for, @geo_result.source.blob.key)

      #less hacky way to get path but still not best, may be best though
      path = ActiveStorage::Blob.service.send(:path_for, @geo_result.source.blob.key)

      #open it as the forced extension dictates because blobs are stored without an 
      #extension
      excel_file = Roo::Spreadsheet.open(path, {:extension => "xlsx"})

      puts excel_file.info

      #so we get first sheet
      sheet = excel_file.sheet(0)

      if params[:commit] == "geocode" 

        bad_item = []

        if address_col < 1
          bad_item << "Incorrect address column selected"
        end
        if address_col > sheet.last_column
          bad_item << " Address column selected farther than columns on sheet"
        end
        if start_row < 1
          bad_item << "Incorrect start row entered"
        end 

        if start_row > sheet.last_row
          bad_item << "Start row past end of rows"
        end 

        #we have an error flash error and redirect before exiting early
        if bad_item.length > 0
          flash[:danger] = bad_item.to_sentence(last_word_connector: ", and ")
          redirect_to action: "show", id: @geo_result[:id]
          return
        end

        #when we get a nil returned for geocoding we put address in here
        bad_address = []


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
          else
            #bad address found
            bad_address << info
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

        flash[:notice] = "File geocoded"
        if bad_address.length > 0
          bad_prefix = "Following addresses could not be found "
          bad_result = bad_address.to_sentence(last_word_connector: ", and ")
          flash[:danger] = "#{bad_prefix}#{bad_result}"

        end

      else
        #here we'll make the lat lon creation

        bad_item = []

        if address_col < 1
          bad_item << "Incorrect address column selected"
        end
        if address_col >= sheet.last_column
          bad_item << " Address column selected farther than columns on sheet"
        end
        if start_row < 1
          bad_item << "Incorrect start row entered"
        end 

        if start_row >= sheet.last_row
          bad_item << "Start row past end of rows"
        end 

        if lat_col < 1
          bad_item << "Incorrect Latitude column selected"
        end

        if lat_col > sheet.last_column
          bad_item << " Latitude column selected farther than columns on sheet"
        end

        if lon_col < 1
          bad_item << "Incorrect Longitude column selected"
        end

        if lon_col > sheet.last_column
          bad_item << " Longitude column selected farther than columns on sheet"
        end

        #we have an error flash error and redirect before exiting early
        if bad_item.length > 0
          flash[:danger] = bad_item.to_sentence(last_word_connector: ", and ")
          redirect_to action: "show", id: @geo_result[:id]
          return
        end

        kml = KMLFile.new
        folder = KML::Folder.new(:name => "data")

        for at in start_row..sheet.last_row+1
          #top left is 1,1 cell also works by y,x
          address = sheet.cell(at,address_col)
          lat = sheet.cell(at,lat_col)
          lon = sheet.cell(at,lon_col)

          #valid coords work like this
          #lat -90 < x < 90
          #lon -180 < y < 180

          if lat > -90 and lat < 90 and lon > -180 and lon < 180
            folder.features << KML::Placemark.new(
              :name =>address,
              :geometry => KML::Point.new(:coordinates => {:lat => lat, :lng => lon})
            )
          end
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
        flash[:notice] = "KML created"
      end

      #we made it here return to page to get proper alert and let the click to download
      #cant force download cause redirect stops working when we send user file
      redirect_to action: "show", id: @geo_result[:id]

    end

    def new
      @geo_result = GeoResult.new()
      
      
    end

    def destroy
      @geo_result = GeoResult.find(params[:id])
      @geo_result.destroy
      
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
  