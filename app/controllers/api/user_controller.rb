class Api::UserController < ActionController::API
  # ensure username unique
  # pass a basic security audit (e.g. password complexity).
  def create
    redis = Redis.new
    redis.set('testuser', 'newpw')
    # puts request.body.read
    json_body = JSON.parse(request.body.read, symbolize_names: false)
    render json: {username: 'testuser', body: json_body}
  end

  def update
    redis = Redis.new
    redis.set('testuser', 'testpw')    
  end

  def show
    redis = Redis.new
    data = redis.get('testuser')

    render json: {username: 'testuser', data: data}
  end
end
