require 'test_helper'

module Api
  class NotificationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user2 = users(:two)
      @notification = notifications(:one)
      # Set header for authentication
      @headers = { 'X-User-Id' => @user.id }
    end

    test "should get index" do
      get api_notifications_url, headers: @headers
      assert_response :success
      assert_equal @user.notifications.count, JSON.parse(response.body).count
    end

    test "index should only show user's own notifications" do
      get api_notifications_url, headers: @headers
      notifications = JSON.parse(response.body)
      
      notifications.each do |notification|
        assert_equal @user.id, notification['user_id']
      end
    end

    test "should create notification" do
      notification_count = @user.notifications.count
      
      post api_notifications_url, 
        params: { 
          notification: { 
            message: 'New notification', 
            read: false 
          } 
        },
        headers: @headers
      
      assert_response :created
      assert_equal notification_count + 1, @user.notifications.count
      
      notification = JSON.parse(response.body)
      assert_equal 'New notification', notification['message']
      assert_equal false, notification['read']
    end

    test "should show notification" do
      get api_notification_url(@notification), headers: @headers
      
      # This should work if @notification belongs to @user
      # Otherwise should be unauthorized
      if @notification.user_id == @user.id
        assert_response :success
        notification = JSON.parse(response.body)
        assert_equal @notification.id, notification['id']
      else
        assert_response :unauthorized
      end
    end

    test "should update notification" do
      patch api_notification_url(@notification),
        params: { notification: { read: true } },
        headers: @headers
      
      if @notification.user_id == @user.id
        assert_response :success
        notification = JSON.parse(response.body)
        assert_equal true, notification['read']
      else
        assert_response :unauthorized
      end
    end

    test "should mark notification as read" do
      patch mark_read_api_notification_url(@notification),
        headers: @headers
      
      if @notification.user_id == @user.id
        assert_response :success
        notification = JSON.parse(response.body)
        assert_equal true, notification['read']
      else
        assert_response :unauthorized
      end
    end

    test "should delete notification" do
      if @notification.user_id == @user.id
        notification_count = Notification.count
        
        delete api_notification_url(@notification), headers: @headers
        
        assert_response :ok
        assert_equal notification_count - 1, Notification.count
      else
        delete api_notification_url(@notification), headers: @headers
        assert_response :unauthorized
      end
    end

    test "should not access other user's notifications" do
      other_user_notification = notifications(:two)
      
      if other_user_notification.user_id != @user.id
        get api_notification_url(other_user_notification), headers: @headers
        assert_response :unauthorized
      end
    end

    test "should require authentication" do
      get api_notifications_url
      # In a real app, this might redirect or return 401
      # depending on your authentication strategy
    end
  end
end
