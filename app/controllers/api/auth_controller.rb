class Api::AuthController < ActionController::API

  # It should respond with 200 OK messages for correct requests, 
  # and 401 for failing authentication requests.
  # It should do proper error checking, with error responses in a JSON response body.
  def create
    username = params[:username]
    # track num attempts?

    pw_hash = redis = Redis.new

    json_body = JSON.parse(request.body.read, symbolize_names: false)

    match = (pw_hash == BCrypt::Password.new json_body[:passwd])

    if match
      token = nil
      render json: {username: username, token: token}
    else
      render json: {error: 'password does not match'}
    end
  end


  # logout
  # require token
  def delete
    redis = Redis.new

    redis.get(nil)

    given_token = json_body[:token]
  end
end
