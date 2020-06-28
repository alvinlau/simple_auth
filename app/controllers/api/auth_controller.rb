class Api::AuthController < ActionController::API
  def create
    username = params[:username]
    # track num attempts?

    begin
      json_body = JSON.parse(request.body.read, symbolize_names: true)
    rescue
      render json: {error: 'malformed body'} and return
    end

    redis = Redis.new
    pw_key = "pw-#{username}"
    stored_pw_hash = redis.get(pw_key)

    unless stored_pw_hash
      # don't give away whether the user exists or not
      render json: {error: "problem logging in, check username or password?"} and return
    end

    match = (stored_pw_hash == BCrypt::Password.new json_body[:passwd])

    if match
      require 'securerandom'
      token = SecureRandom.hex
      token_key = "token-#{username}"
      redis.get(token_key)

      # make the ttl a config setting
      redis.set(token_key, token, {ex: 600})

      render json: {username: username, token: token}, status: 200
    else
      render json: {error: 'password does not match'}, status: 401
    end
  end


  # logout
  def delete
    redis = Redis.new
    token_key = "token-#{username}"
    stored_token = redis.get(token_key)

    given_token = json_body[:token]

    unless given_token && stored_token
      render json: {msg: 'user is not logged in'} and return
    end

    if given_token == stored_token
      redis.del(token_key)
      render json: {msg: 'logged out successfully'}
    end
  end
end
