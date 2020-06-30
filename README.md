# README

Using Ruby on Rails as your framework and Redis for data storage, we need an authentication API for internal services to create and authenticate users. This API should be RESTful and use JSON. It should be fast and secure, and be able to pass a basic security audit (e.g. password complexity). If there are areas of security that your solution hasn't had time to address they should be annotated for future development.


The API should be able to create a new login with a username and password, ensuring that usernames are unique. It should also be able to authenticate this login at a separate end point. It should respond with 200 OK messages for correct requests, and 401 for failing authentication requests. It should do proper error checking, with error responses in a JSON response body.


## Quick Notes

The core skeleton is generated as a Rails API project via `rails new simple_auth --api --skip-active-record --skip-test`, and since we're not outright using a database to store the data I started without ActiveRecord.

I have taken a rudimentary approach to implementing this service.  It is possible to incorporate more robust gems and libraries including `pundit`, `devise`, `jwt`, `fast_jsonapi`, but with the scope of this project, I took the simpler approach to have fewer lines of code and the ability to see the business logic clearly.  This rudimentay approach includes simply using `BCrypt` to hash the passwords, and using `SecureRandom` to generate tokens.  Surely there are more robust gems to do the same thing, and as of now it is easy to replace the implementation using those other gems.

I made an effort to use appropriate HTTP response codes for the various scenarios, but they can still be revised again for improvements.

Some of the bigger possible overhauls would be using Rails features like making some kind of model for users and auth tokens or sessions, but nothing obvious turned out when I searched for models backed by Redis.  It could be looked at again.  With Rails models, we can make use of built-in features like `has_secure_password` instead of writing our own hashing and such.  Since we still have Rails (API) as our base, Rails does take care of certain kinds of spam or man-in-the-middle attacks.


## Usage

How to run the service

* `bundle install` in root directory
* then `rails s` or `bundle exec puma`

Ruby version

* This service has been tested against Ruby version `2.7.0`

System dependencies

* Redis is installed and running on localhost and default port (6379)

How to run the test suite

* `rspec spec`


## Future Improvements

  - Handle multiple concurrent logins for one user: this will mean storing an array in Redis for a user's auth tokens
  - Handle multiple failed login attempts (I think Rails)
  - Logging
  - Just set the username and password hash in Redis when creating new users in RSpec, it saves one call to the service
  - User the `FactoryBot` and `Faker` gems to mock usernames and passwords instead of hardcoding
  - Configure the host and port for the Redis instance to connect to, as well as the time-to-live for the tokens
  - Add versioning for the API, I consciously did not include it to keep things simple, and we're not foreseeing a new version so soon yet
  - Require the user to provide the existing password when updating password
  - Code coverage
  - Dockerfile for containerization


## Further Notes

Since the usernames are unique in the requirements, I've used them as ids.  We could always pass user ids instead of usernames in the url.  I still stick to having them in the url paths to be more RESTful (as opposed to having the user ids in the body), even though we don't exactly have "resouces" or models in this implementation.

Overall style is idionmatic Ruby, I try to avoid Ruby golf but that can definitely be shown in another occurence.

## References and Guides

https://thinkster.io/tutorials/angular-rails/creating-api-routes-and-controllers

https://codeburst.io/how-to-build-a-good-api-using-rubyonrails-ef7eadfa3078?gi=83c35dd15293

https://www.pluralsight.com/guides/token-based-authentication-with-ruby-on-rails-5-api

https://medium.com/@sedwardscode/how-to-properly-test-a-rails-api-with-rspec-f15cbe1dfd11

Not all of these are used in full, but could be if we make use of complete Rails and have more than simple scope.
