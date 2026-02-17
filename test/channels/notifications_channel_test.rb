require 'test_helper'

class NotificationsChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = users(:one)
    stub_connection current_user: @user
  end

  test "subscribes to a stream when websocket connects" do
    subscribe
    assert subscription.confirmed?
    assert_has_stream_for @user
  end

  test "broadcast notification_created event" do
    subscribe
    
    notification = @user.notifications.create(message: "Test notification")
    
    assert_broadcast_on(
      ActionCable.server.broadcaster_for(@user),
      hash_including(
        type: 'notification_created',
        notification: hash_including('message' => 'Test notification')
      )
    )
  end

  test "broadcast notification_updated event" do
    subscribe
    
    notification = @user.notifications.create(message: "Test notification")
    notification.update(read: true)
    
    assert_broadcast_on(
      ActionCable.server.broadcaster_for(@user),
      hash_including(
        type: 'notification_updated',
        notification: hash_including('read' => true)
      )
    )
  end

  test "broadcast notification_destroyed event" do
    subscribe
    
    notification = @user.notifications.create(message: "Test notification")
    notification_id = notification.id
    notification.destroy
    
    assert_broadcast_on(
      ActionCable.server.broadcaster_for(@user),
      hash_including(
        type: 'notification_destroyed',
        notification_id: notification_id
      )
    )
  end

  test "can perform mark_read action" do
    subscribe
    
    @notification = @user.notifications.create(message: "Test notification")
    
    perform :mark_read, { id: @notification.id }
    
    @notification.reload
    assert @notification.read?
  end
end
