class GeoResultsControler < ApplicationController
    def Create
      #
      geo_result = geo_result.Create!(geo_result_params)
  
    end
    
    private
    def geo_result_params
        #
        params.require(:geo_result).permit(:search, :result)
    end 
end
  