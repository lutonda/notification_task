module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Try JWT token first
      if (token = extract_token_from_cookie || extract_token_from_query)
        user = decode_jwt_token(token)
        return user if user
      end

      # Fallback to session-based authentication
      if verified_user = User.find_by(id: session['user_id'])
        return verified_user
      end

      reject_unauthorized_connection
    end

    def extract_token_from_cookie
      cookies.encrypted[:auth_token]
    end

    def extract_token_from_query
      request.params['token']
    end

    def decode_jwt_token(token)
      secret = Rails.application.secrets.jwt_secret || 'fallback-secret-key'
      payload = JWT.decode(token, secret, true, algorithm: 'HS256').first
      User.find_by(id: payload['user_id'])
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.warn("ActionCable JWT decode error: #{e.message}")
      nil
    end
  end
end
