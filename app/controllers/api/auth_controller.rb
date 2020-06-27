class AuthController < ActionController::API

  # It should respond with 200 OK messages for correct requests, 
  # and 401 for failing authentication requests.
  # It should do proper error checking, with error responses in a JSON response body.
  def create
    redis = Redis.new

  end


  # logout
  # require token
  def delete
    redis = Redis.new
  end
end
