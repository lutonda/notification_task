class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def mark_read(data)
    notification = Notification.find(data['id'])
    if notification.user_id == current_user.id
      notification.update(read: true)
      broadcast_to_user(notification)
    end
  end

  private

  def broadcast_to_user(notification)
    NotificationsChannel.broadcast_to(
      current_user,
      {
        type: 'notification_updated',
        notification: notification.as_json
      }
    )
  end
end
