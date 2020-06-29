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

    end

    it 'does not do anything for non-existing user' do
      # no user is created
    end

    it 'rejects attempt to change password without valid token' do

    end

    it 'changing password will NOT invalidate existing login auth token' do
      # user can still logout

    end

    it 'should allow changing password again after changing once already while logged in' do

    end

  end
end
