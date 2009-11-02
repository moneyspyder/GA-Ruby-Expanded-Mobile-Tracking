ActionController::Routing::Routes.draw do |map|
  map.connect '', :controller => 'ga', :action => 'index'
  map.connect 'utm_gif', :controller => 'ga', :action => 'utm_gif'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
