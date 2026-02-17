module Api
  class AuthenticationController < ApplicationController
    # POST /api/authentication/login
    def login
      user = User.find_by(email: params[:email])
      
      if user
        service = AuthenticationService.new(user)
        token = service.generate_token
        
        render json: {
          message: 'Login successful',
          token: token,
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        }, status: :ok
      else
        render json: {
          error: 'Invalid credentials',
          message: 'User not found'
        }, status: :unauthorized
      end
    rescue StandardError => e
      render json: {
        error: 'Authentication failed',
        message: e.message
      }, status: :unauthorized
    end

    # GET /api/authentication/verify
    def verify
      token = request.headers['Authorization']&.split(' ')&.last
      
      if token
        begin
          user = AuthenticationService.decode_token(token)
          render json: {
            message: 'Token is valid',
            user: {
              id: user.id,
              name: user.name,
              email: user.email
            }
          }, status: :ok
        rescue StandardError => e
          render json: {
            error: 'Invalid token',
            message: e.message
          }, status: :unauthorized
        end
      else
        render json: {
          error: 'No token provided',
          message: 'Authorization header missing'
        }, status: :unauthorized
      end
    end
  end
end
