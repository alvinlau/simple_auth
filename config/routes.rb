Rails.application.routes.draw do
  namespace :api do
    get '/users/:username', to: 'user#show'
    post '/users/:username', to: 'user#create'
    patch '/users/:username', to: 'user#update'

    post '/auth/:username', to: 'auth#create'
    delete '/auth/:username', to: 'auth#delete'
  end
end
