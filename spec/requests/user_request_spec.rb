require 'rails_helper'

RSpec.describe "UserController", type: :request do
  before(:each) do
    Redis.new.flushall
  end

  describe 'create user' do
    it 'accepts valid username and password' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['msg']).to eq 'user pika created successfully'
      expect(BCrypt::Password.new(Redis.new.get('passwd-pika'))).to eq 'chu'
    end

    it 'requires alphanumeric characters for username' do

    end

    it 'require password matching password rules' do

    end

    it 'does not accept malformed json body' do
      post '/api/users/junk', params: {a: 10}
      expect(response).to have_http_status(400)
      expect(JSON.parse(response.body)['error']).to eq 'malformed body'
    end

    it 'does not allow creating user with existing username' do
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
      post '/api/users/pika', params: {passwd: 'chu'}.to_json
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

    it 'changing password will invalidate existing login auth tokens' do

    end

  end
end
