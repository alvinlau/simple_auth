require 'rails_helper'

RSpec.describe "UserController", type: :request do
  before(:each) do
    Redis.new.flushall
  end

  describe 'create user' do
    it 'accepts valid username and password' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['msg']).to eq 'user pika created successfully'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'chuchu+0'
    end

    it 'requires alphanumeric characters only for username' do
      post '/api/users/pika-67&', params: {passwd: 'chuchu+0'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq 'username must be alphanumeric'
      expect(Redis.new.get('passwd-pika')).to be nil
    end

    it 'requires password matching password rules' do
      error = 'password must have at least one letter, one number, one special character, '\
                'and at least 8 characters long'
      redis = Redis.new

      post '/api/users/pika', params: {passwd: 'chuchuchu'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq error
      expect(redis.get('passwd-pika')).to be nil

      post '/api/users/pika', params: {passwd: 'chuchu00'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq error

      post '/api/users/pika', params: {passwd: 'short'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq error

      post '/api/users/pika', params: {passwd: '12345678'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq error

      post '/api/users/pika', params: {passwd: '!!!'}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq error

      expect(redis.get('passwd-pika')).to be nil
    end

    it 'does not accept malformed json body' do
      post '/api/users/junk', params: {a: 10}
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq 'malformed body'
    end

    it 'does not allow creating user with existing username' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      expect(response).to have_http_status(403)
      expect(JSON.parse(response.body)['error']).to eq 'username pika already exists'
    end

    it 'requires a password to be provided' do
      post '/api/users/char', params: {}.to_json
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq 'no password provided'
    end
  end
  

  describe 'update password' do
    it 'updates password with valid token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      token = JSON.parse(response.body)['token']
      patch '/api/users/pika', params: {passwd: 'newpw=01', token: token}.to_json

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['msg']).to eq 'password updated successfully'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'newpw=01'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'chuchu+0'
    end

    it 'does not change anything for non-existing user' do
      patch '/api/users/nosuchuser', params: {passwd: 'somepw', token: 'randomtoken'}.to_json
      expect(response).to have_http_status(400)
      expect(Redis.new.get('passwd-nosuchuser')).to be nil
    end

    it 'rejects attempt to change password without valid token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      patch '/api/users/pika', params: {passwd: 'newpw=01', token: 'invalidtoken'}.to_json

      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)['error']).to eq 'token is invalid'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'chuchu+0'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'newpw=01'
    end

    it 'cannot change password without being logged in' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      patch '/api/users/pika', params: {passwd: 'newpw=01', token: 'invalidtoken'}.to_json

      expect(response).to have_http_status(401)
      expect(JSON.parse(response.body)['error']).to eq 'user is not logged in'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'chuchu+0'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'newpw=01'
    end

    it 'changing password will NOT invalidate existing login auth token' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      token = JSON.parse(response.body)['token']

      patch '/api/users/pika', params: {passwd: 'newpw=01', token: token}.to_json
      redis = Redis.new
      expect(redis.get('token-pika')).not_to be nil

      delete '/api/auth/pika', params: {token: token}.to_json
      body = JSON.parse(response.body)

      expect(response).to have_http_status(200)
      expect(body['msg']).to eq 'logged out successfully'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'newpw=01'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'chuchu+0'
      expect(redis.get('token-pika')).to be nil
    end

    it 'should allow changing password again after changing it once already while logged in' do
      post '/api/users/pika', params: {passwd: 'chuchu+0'}.to_json
      post '/api/auth/pika', params: {passwd: 'chuchu+0'}.to_json
      token = JSON.parse(response.body)['token']

      patch '/api/users/pika', params: {passwd: 'newpw=01', token: token}.to_json
      redis = Redis.new
      expect(redis.get('token-pika')).not_to be nil

      patch '/api/users/pika', params: {passwd: 'newpw=02', token: token}.to_json
      redis = Redis.new
      expect(redis.get('token-pika')).not_to be nil

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['msg']).to eq 'password updated successfully'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'newpw=02'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'newpw=01'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).not_to eq 'chuchu+0'
    end

  end
end
