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
    
    render json: {username: username, body: json_body}, status: 200
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
    key = "passwd-#{username}"
    existing_user = redis.get(key)

    unless existing_user
      error = "username #{username} does not exist"
      render json: {error: error }, status: 400 and return
    end
    
    unless json_body[:passwd]
      render json: {error: 'no password provided'} and return
    end

    pw_hash = BCrypt::Password.create(json_body[:passwd])
    redis.set(key, pw_hash, {xx: true})
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
