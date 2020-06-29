require 'rails_helper'

RSpec.describe "AuthController", type: :request do
  before(:each) do
    Redis.new.flushall
  end

  describe 'login' do
    it 'generates token for valid username and password' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      expect(response).to have_http_status(200)
      
      body = JSON.parse(response.body)
      redis = Redis.new
      expect(body['msg']).to eq 'logged in successfully'
      expect(body['token']).to eq redis.get('token-pika')
      # password is still retained after login
      expect(redis.get('passwd-pika')).not_to be nil
    end

    it 'cannot grant login for non-existing username' do
      post '/api/auth/doesnotexist', params: {passwd: 'somepw'}.to_json
      expect(response).to have_http_status(400)
      body = JSON.parse(response.body)
      expect(body['token']).to be nil
    end

    it 'does not accept incorrect password for existing user' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'wrongpw'}.to_json
      expect(response).to have_http_status(401)
      body = JSON.parse(response.body)
      expect(body['error']).to eq 'password does not match'
    end

    it 'handles user that is already logged in' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
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
    it 'completes logout for user with valid token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      body = JSON.parse(response.body)
      
      delete '/api/auth/pika', params: {token: body['token']}.to_json
      body = JSON.parse(response.body)
      expect(response).to have_http_status(200)
      expect(body['msg']).to eq 'logged out successfully'
      redis = Redis.new
      expect(redis.get('token-pika')).to be nil
      # password is still retained after logout
      expect(redis.get('passwd-pika')).not_to be nil
    end

    it 'rejects logout request with invalid token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      
      delete '/api/auth/pika', params: {token: 'invalidtoken'}.to_json
      body = JSON.parse(response.body)

      expect(response).to have_http_status(401)
      expect(body['error']).to eq 'invalid token'
      expect(Redis.new.get('token-pika')).not_to be nil
    end

    it 'rejects logout request with no token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      body = JSON.parse(response.body)
      
      delete '/api/auth/pika', params: {}.to_json
      expect(response).to have_http_status(401)
      body = JSON.parse(response.body)
      expect(body['msg']).to eq 'user is not logged in'
      expect(Redis.new.get('token-pika')).not_to be nil
    end

    it 'handles attempt to logout again after successful logout' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      body = JSON.parse(response.body)
      
      delete '/api/auth/pika', params: {token: body['token']}.to_json
      expect(response).to have_http_status(200)

      delete '/api/auth/pika', params: {token: body['token']}.to_json
      expect(response).to have_http_status(401)
      body = JSON.parse(response.body)
      expect(body['msg']).to eq 'user is not logged in'
      expect(Redis.new.get('token-pika')).to be nil
    end

    it 'can perform login again after logout' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      body = JSON.parse(response.body)
      token1 = body['token']
      
      delete '/api/auth/pika', params: {token: token1}.to_json

      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      body = JSON.parse(response.body)
      token2 = body['token']

      expect(body['msg']).to eq 'logged in successfully'
      expect(token1).not_to eq token2
    end
  end
end
