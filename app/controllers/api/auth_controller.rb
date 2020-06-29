class Api::AuthController < ActionController::API

  # login
  # returns an auth token
  def create
    username = params[:username]

    begin
      json_body = JSON.parse(request.body.read, symbolize_names: true)
    rescue
      render json: {error: 'malformed body'}, status: 400 and return
    end

    redis = Redis.new
    pw_key = "passwd-#{username}"
    stored_pw_hash = redis.get(pw_key)

    unless stored_pw_hash
      # don't give away whether the user exists or not
      error = "problem logging in, check username or password?"
      render json: {error: error}, status: 400 and return
    end

    match = (BCrypt::Password.new(stored_pw_hash) == json_body[:passwd])

    if match
      token_key = "token-#{username}"
      existing_token = redis.get(token_key) 
      if existing_token
        # give back currently logged in token for now so if the user is logged in
        # on another device already, that device is still logged in
        # future: allow multiple tokens for concurrent login?

        # renew the ttl for the existing token
        redis.set(token_key, existing_token, {ex: 600})
        render json: {msg: 'logged in successfully', token: existing_token}, status: 200
      else
        require 'securerandom'
        new_token = SecureRandom.hex

        redis.set(token_key, new_token, {ex: 600})
        render json: {msg: 'logged in successfully', token: new_token}, status: 200
      end
    else
      render json: {error: 'password does not match'}, status: 401
    end
  end


  # logout
  # requires auth token from login
  def delete
    username = params[:username]

    begin
      json_body = JSON.parse(request.body.read, symbolize_names: true)
    rescue
      render json: {error: 'malformed body'}, status: 400 and return
    end

    redis = Redis.new
    token_key = "token-#{username}"
    stored_token = redis.get(token_key)
    given_token = json_body[:token]

    unless given_token && stored_token
      render json: {msg: 'user is not logged in'}, status: 401 and return
    end

    if given_token == stored_token
      redis.del(token_key)
      render json: {msg: 'logged out successfully'}, status: 200
    else
      # might be attempt to log someone else out
      render json: {error: 'invalid token'}, status: 401
    end
  end

  private

  def show
    username = params[:username]
    redis = Redis.new
    key = "token-#{username}"
    token = redis.get(key)
    render json: {username: username, token: token}
  end
end
