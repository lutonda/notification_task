require 'test_helper'

class AuthenticationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should generate JWT token" do
    service = AuthenticationService.new(@user)
    token = service.generate_token
    
    assert_not_nil token
    assert_kind_of String, token
    
    # Token should have 3 parts separated by dots (header.payload.signature)
    assert_equal 3, token.split('.').length
  end

  test "should decode valid token" do
    service = AuthenticationService.new(@user)
    token = service.generate_token
    
    decoded_user = AuthenticationService.decode_token(token)
    
    assert_equal @user.id, decoded_user.id
  end

  test "should raise error on invalid token" do
    assert_raises do
      AuthenticationService.decode_token('invalid-token')
    end
  end

  test "should include user data in token" do
    service = AuthenticationService.new(@user)
    token = service.generate_token
    
    # Decode without verification to inspect payload
    decoded = JWT.decode(token, nil, false)
    payload = decoded.first
    
    assert_equal @user.id, payload['user_id']
    assert_equal @user.email, payload['email']
  end

  test "token should have expiration" do
    service = AuthenticationService.new(@user)
    token = service.generate_token
    
    # Decode to check exp claim
    decoded = JWT.decode(token, nil, false)
    payload = decoded.first
    
    assert_not_nil payload['exp']
    assert payload['exp'] > Time.current.to_i
  end

  test "should allow custom expiration time" do
    service = AuthenticationService.new(@user)
    token = service.generate_token(expires_in: 7.days)
    
    decoded = JWT.decode(token, nil, false)
    payload = decoded.first
    
    # Token expiration should be approximately 7 days from now
    expected_exp = (Time.current + 7.days).to_i
    assert (payload['exp'] - expected_exp).abs < 60  # Within 60 seconds
  end
end
