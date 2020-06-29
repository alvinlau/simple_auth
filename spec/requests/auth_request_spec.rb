require 'rails_helper'

RSpec.describe "AuthController", type: :request do
  before(:each) do
    Redis.new.flushall
  end

  describe 'login' do
    it 'generates token for valid username and password' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      post '/api/auth/pika', params: {passwd: 'chu'}.to_json
      expect(response).to have_http_status(200)
      
      body = JSON.parse(response.body)
      redis = Redis.new
      expect(body['msg']).to eq 'logged in successfully'
      expect(body['token']).to eq redis.get('token-pika')
      # password is still stored after login
      expect(redis.get('passwd-pika')).not_to be nil
    end

    it 'cannot grant login for non-existing username' do
      post '/api/auth/doesnotexist', params: {passwd: 'somepw'}.to_json
      expect(response).to have_http_status(400)
      body = JSON.parse(response.body)
      expect(body['token']).to be nil
    end

    it 'does not accept incorrect password for existing user' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      post '/api/auth/pika', params: {passwd: 'wrongpw'}.to_json
      expect(response).to have_http_status(401)
      body = JSON.parse(response.body)
      expect(body['error']).to eq 'password does not match'
    end


    it 'handles user that is already logged in' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      post '/api/auth/pika', params: {passwd: 'chu'}.to_json
      post '/api/auth/pika', params: {passwd: 'chu'}.to_json
      expect(response).to have_http_status(200)
      
      body = JSON.parse(response.body)
      redis = Redis.new
      expect(body['msg']).to eq 'logged in successfully'
      expect(body['token']).to eq redis.get('token-pika')
    end


    it 'does not accept malformed json body' do
      post '/api/auth/junk', params: {a: 10}
      expect(response).to have_http_status(400)
      body = JSON.parse(response.body)
      expect(body['error']).to eq 'malformed body'
      expect(body['token']).to be nil
    end
  end

  describe 'logout' do

  end
end
