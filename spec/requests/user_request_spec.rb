require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe 'create user' do
    it 'accepts valid username and password' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['msg']).to eq 'user pika created successfully'
    end

    it 'does not accept malformed json body' do

    end

    it 'does not allow creating user with existing username' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      expect(response).to have_http_status(403)
    end

    it 'requires a password to be provided' do
      post '/api/users/char', params: {}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq 'no password provided'
    end
  end
end
