Rails.application.routes.draw do
  root :to => "application#index"

  post "application/login"
  post "application/logout"
  get "application/main"

  get "admin/main"
  get "admin/users"
  get "admin/user_edit"
  post "admin/user_write"
  get "admin/joinrpg"
  post "admin/joinrpg_character_import"

  get "reader/main"
  
  get "writer/main"
  post "writer/event_write"
  get "writer/event_delete"
  get "writer/events"
  get "writer/event"
  get "writer/objects"
  get "writer/object"
  post "writer/object_write"
  get "writer/object_delete"
  get "writer/locations"
  get "writer/location"
  post "writer/location_write"
  get "writer/location_delete"

  get "writer/event_search"
  post "writer/event_do_search"

  get "writer/map"
  get "writer/map_image"

  get "reader/events"
  get "reader/event"
  get "reader/objects"
  get "reader/object"
  get "reader/locations"
  get "reader/location"
  get "reader/event_search"
  get "reader/map"
end
