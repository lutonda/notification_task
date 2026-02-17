class Notification < ApplicationRecord
  belongs_to :user

  after_create :broadcast_creation
  after_update :broadcast_update
  after_destroy :broadcast_destruction

  validates :message, presence: true
  validates :user_id, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }

  private

  def broadcast_creation
    NotificationsChannel.broadcast_to(
      user,
      {
        type: 'notification_created',
        notification: as_json
      }
    )
  end

  def broadcast_update
    NotificationsChannel.broadcast_to(
      user,
      {
        type: 'notification_updated',
        notification: as_json
      }
    )
  end

  def broadcast_destruction
    NotificationsChannel.broadcast_to(
      user,
      {
        type: 'notification_destroyed',
        notification_id: id
      }
    )
  end
end
