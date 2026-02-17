module Api
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!, except: [:index]
      rescue_from AuthenticationError, with: :handle_authentication_error
      rescue_from AuthorizationError, with: :handle_authorization_error
    end

    class AuthenticationError < StandardError; end
    class AuthorizationError < StandardError; end

    private

    def authenticate_user!
      unless current_user
        raise AuthenticationError, 'Authentication required'
      end
    end

    def current_user
      @current_user ||= extract_user_from_auth_header
    end

    def extract_user_from_auth_header
      auth_header = request.headers['Authorization']
      
      if auth_header&.start_with?('Bearer ')
        token = auth_header[7..]
        decode_jwt_token(token)
      elsif user_id = request.headers['X-User-Id']
        User.find_by(id: user_id)
      end
    rescue StandardError => e
      Rails.logger.error("Authentication error: #{e.message}")
      nil
    end

    def decode_jwt_token(token)
      secret = Rails.application.secrets.jwt_secret || 'fallback-secret-key'
      payload = JWT.decode(token, secret, true, algorithm: 'HS256').first
      User.find(payload['user_id'])
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.warn("JWT decode error: #{e.message}")
      nil
    end

    def authorize_notification!(notification)
      if notification.user_id != current_user.id
        raise AuthorizationError, 'You are not authorized to access this notification'
      end
    end

    def handle_authentication_error(error)
      render json: {
        error: 'Unauthorized',
        message: error.message
      }, status: :unauthorized
    end

    def handle_authorization_error(error)
      render json: {
        error: 'Forbidden',
        message: error.message
      }, status: :forbidden
    end
  end
end
