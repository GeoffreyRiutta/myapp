require 'stringio'

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

    def new
      @geo_result = GeoResult.new()
      
      
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
  