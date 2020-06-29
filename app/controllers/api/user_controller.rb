module Api
  class Api::UserController < ActionController::API

    # creates user and password
    # stores the password hash
    def create
      username = params[:username]
      unless validate_username username
        render json: {error: 'username must be alphanumeric'}, status: 400 and return
      end

      begin
        json_body = JSON.parse(request.body.read, symbolize_names: true)
      rescue
        render json: {error: 'malformed body'}, status: 400 and return
      end

      redis = Redis.new
      key = "passwd-#{username}"
      existing_user = redis.get(key)

      if existing_user
        error = "username #{username} already exists"
        render json: {error: error }, status: 403 and return
      end

      unless json_body[:passwd]
        render json: {error: 'no password provided'}, status: 400 and return
      end

      if validate_password(json_body[:passwd])
        pw_hash = BCrypt::Password.create(json_body[:passwd])
        redis.set(key, pw_hash, {nx: true})
        render json: {msg: "user #{username} created successfully"}, status: 200
      else
        error = 'password must have at least one letter, one number, one special character, '\
                'and at least 8 characters long'
        render json: {error: error}, status: 400 and return
      end
    end


    # updates password
    def update
      username = params[:username]
      
      begin
        json_body = JSON.parse(request.body.read, symbolize_names: true)
      rescue
        render json: {error: 'malformed body'} and return
      end

      redis = Redis.new
      pw_key = "passwd-#{username}"
      stored_pw_hash = redis.get(pw_key)

      unless stored_pw_hash
        # don't give away whether the user exists or not
        error = "problem updating password, check username or password?"
        render json: {error: error}, status: 400 and return
      end

      token_key = "token-#{username}"
      stored_token = redis.get(token_key)
      given_token = json_body[:token]

      unless given_token && stored_token
        render json: {error: 'user is not logged in'}, status: 401 and return
      end
      
      unless json_body[:passwd]
        render json: {error: 'no password provided'} and return
      end

      # future/optional: require user to provide old password as well

      if stored_token == given_token
        new_pw_hash = BCrypt::Password.create(json_body[:passwd])
        redis.set(pw_key, new_pw_hash, {xx: true})
        render json: {msg: "password updated successfully"}, status: 200
      else
        render json: {error: 'token is invalid'}, status: 401
      end
    end

    private 

    def show
      username = params[:username]
      redis = Redis.new
      key = "passwd-#{username}"
      pw_hash = redis.get(key)
      render json: {username: username, pw_hash: pw_hash}
    end

    def validate_username(username)
      username =~ /^[a-zA-Z0-9]+$/
    end
    
    def validate_password(password)
      password =~ /^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[\W]).{8,}$/
    end
  end
end