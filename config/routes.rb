Rails.application.routes.draw do
  root to: 'visitors#index'
  resources :visitors do
      get :zero_island, on: :collection
      get :cci_loc, on: :collection
      get :cci_search, on: :collection
  end
end
