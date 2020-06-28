class Api::UserController < ActionController::API
  # pass a basic security audit (e.g. password complexity).
  def create
    username = params[:username]
    begin
      json_body = JSON.parse(request.body.read, symbolize_names: false)
      # throw if no pw field
    rescue
      render json: {error: 'malformed body'} and return
    end

    redis = Redis.new
    existing_user = redis.get(username)

    if existing_user
      render json: {error: "username #{username} already exists"} and return
    end

    pw_hash = BCrypt::Password.create(json_body[:passwd])
    redis.set(username, pw_hash)
    
    render json: {username: username, body: json_body}
  end


  # require token
  def update
    username = params[:username]
    redis = Redis.new
    redis.set('testuser', 'testpw')
  end


  def show
    username = params[:username]
    redis = Redis.new
    data = redis.get(username)
    render json: {username: username, data: data}
  end


  private 
  
  def validate_pw(pw)

  end
end
