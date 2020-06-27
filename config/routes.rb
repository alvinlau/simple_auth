# ❯ rake routes
# Prefix Verb   URI Pattern                       Controller#Action
# api_v1 GET    /api/v1/users/:username(.:format) api/v1/users#show
#        POST   /api/v1/users/:username(.:format) api/v1/users#create
#        PATCH  /api/v1/users/:username(.:format) api/v1/users#update
#        POST   /api/v1/auth/:username(.:format)  api/v1/auth#create
#        DELETE /api/v1/auth/:username(.:format)  api/v1/auth#delete

Rails.application.routes.draw do
  namespace :api do
    # namespace :v1 do
      get '/users/:username', to: 'user#show'
      post '/users/:username', to: 'user#create'
      patch '/users/:username', to: 'user#update'

      post '/auth/:username', to: 'auth#create'
      delete '/auth/:username', to: 'auth#delete'
    # end
  end
end

# Rails.application.routes.draw do
#   namespace :api do
#     resources :users do
#       get '/users/:username', to: 'users#show'

#       post '/users/:username', to: 'users#create'

#       patch '/users/:username', to: 'users#update'
#     end
#   end
# end