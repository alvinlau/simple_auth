class Api::UserController < ActionController::API
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

    pw_hash = BCrypt::Password.create(json_body[:passwd])
    # validate_password(pw_hash)
    redis.set(key, pw_hash, {nx: true})
    
    render json: {msg: "user #{username} created successfully"}, status: 200
  end


  # require token
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
      error = "problem logging in, check username or password?"
      render json: {error: error}, status: 400 and return
    end

    token_key = "token-#{username}"
    stored_token = redis.get(token_key)
    given_token = json_body[:token]

    unless given_token && stored_token
      render json: {msg: 'user is not logged in'}, status: 401 and return
    end
    
    unless json_body[:passwd]
      render json: {error: 'no password provided'} and return
    end

    match = (BCrypt::Password.new(stored_pw_hash) == json_body[:passwd])

    if match
      new_pw_hash = BCrypt::Password.create(json_body[:passwd])
      redis.set(key, new_pw_hash, {xx: true})
      render json: {msg: "password updated successfully"}, status: 200
    else
      render json: {error: 'password does not match'}, status: 401
    end
  end


  def show
    username = params[:username]
    redis = Redis.new
    key = "passwd-#{username}"
    pw_hash = redis.get(key)
    render json: {username: username, pw_hash: pw_hash}
  end


  private 

  def validate_username(username)
    username =~ /^[a-zA-Z0-9]+$/
  end
  
  def validate_password(password)
    password =~ /^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[\W]).{8,}$/
  end
end
