require 'test_helper'

module Api
  class AuthenticationControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
    end

    test "should login with valid email" do
      post api_authentication_login_url, 
        params: { email: @user.email }
      
      assert_response :success
      response_data = JSON.parse(response.body)
      
      assert_equal 'Login successful', response_data['message']
      assert_not_nil response_data['token']
      assert_equal @user.id, response_data['user']['id']
      assert_equal @user.email, response_data['user']['email']
    end

    test "should fail login with invalid email" do
      post api_authentication_login_url, 
        params: { email: 'nonexistent@example.com' }
      
      assert_response :unauthorized
      response_data = JSON.parse(response.body)
      assert_equal 'Invalid credentials', response_data['error']
    end

    test "should verify valid token" do
      service = AuthenticationService.new(@user)
      token = service.generate_token
      
      get api_authentication_verify_url,
        headers: { 'Authorization' => "Bearer #{token}" }
      
      assert_response :success
      response_data = JSON.parse(response.body)
      
      assert_equal 'Token is valid', response_data['message']
      assert_equal @user.id, response_data['user']['id']
    end

    test "should fail verification with invalid token" do
      get api_authentication_verify_url,
        headers: { 'Authorization' => 'Bearer invalid-token' }
      
      assert_response :unauthorized
    end

    test "should fail verification without token" do
      get api_authentication_verify_url
      
      assert_response :unauthorized
      response_data = JSON.parse(response.body)
      assert_equal 'No token provided', response_data['error']
    end
  end
end
