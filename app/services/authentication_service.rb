class AuthenticationService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def generate_token(expires_in: 24.hours)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: (Time.current + expires_in).to_i,
      iat: Time.current.to_i
    }
    
    secret = Rails.application.secrets.jwt_secret || 'fallback-secret-key'
    JWT.encode(payload, secret, 'HS256')
  end

  def self.from_credentials(email, password)
    user = User.find_by(email: email)
    
    if user && user.authenticate(password)
      new(user)
    else
      raise 'Invalid credentials'
    end
  end

  def self.decode_token(token)
    secret = Rails.application.secrets.jwt_secret || 'fallback-secret-key'
    payload = JWT.decode(token, secret, true, algorithm: 'HS256').first
    User.find(payload['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise "Invalid token: #{e.message}"
  end
end
