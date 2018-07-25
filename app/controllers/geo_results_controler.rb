require 'stringio'

class GeoResultsControler < ApplicationController
    def Create
      #right now we are not doing just the search term

      geo_result = geo_result.Create!(geo_result_params)

      
  
    end
    
    private
    def geo_result_params
        #just search, later we may be attaching the result data if fessiable with
        #activestorage
        params.require(:geo_result).permit(:search, :result, :source)
    end 
end
  