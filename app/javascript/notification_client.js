/**
 * Notification WebSocket Client Example
 * 
 * This is an example of how to implement a real-time notification system
 * using ActionCable with a JavaScript/TypeScript frontend.
 */

class NotificationClient {
  constructor(userId, userId) {
    this.userId = userId;
    this.cable = null;
    this.subscription = null;
    this.listeners = [];
    this.baseUrl = 'http://localhost:3000';
    this.wsUrl = 'ws://localhost:3000/cable';
  }

  /**
   * Initialize the WebSocket connection
   */
  async connect() {
    try {
      // Import ActionCable (make sure @rails/actioncable is installed)
      const ActionCable = require('@rails/actioncable');
      
      this.cable = ActionCable.createConsumer(this.wsUrl);
      
      this.subscription = this.cable.subscriptions.create('NotificationsChannel', {
        received: (data) => this.handleMessage(data),
        connected: () => console.log('Connected to notifications'),
        disconnected: () => console.log('Disconnected from notifications'),
        rejected: () => console.log('Connection rejected')
      });
      
      console.log('WebSocket connection established');
    } catch (error) {
      console.error('Failed to connect to WebSocket:', error);
    }
  }

  /**
   * Disconnect from WebSocket
   */
  disconnect() {
    if (this.subscription) {
      this.cable.subscriptions.remove(this.subscription);
    }
  }

  /**
   * Handle incoming messages from server
   */
  handleMessage(data) {
    console.log('Message received:', data);
    
    this.listeners.forEach(listener => {
      listener(data);
    });

    switch (data.type) {
      case 'notification_created':
        this.onNotificationCreated(data.notification);
        break;
      case 'notification_updated':
        this.onNotificationUpdated(data.notification);
        break;
      case 'notification_destroyed':
        this.onNotificationDestroyed(data.notification_id);
        break;
    }
  }

  /**
   * Register a listener for all notification events
   */
  subscribe(callback) {
    this.listeners.push(callback);
  }

  /**
   * Remove a listener
   */
  unsubscribe(callback) {
    this.listeners = this.listeners.filter(l => l !== callback);
  }

  /**
   * Handle new notification
   */
  onNotificationCreated(notification) {
    console.log('New notification:', notification);
    // Update UI to show new notification
    // Example: addNotificationToUI(notification)
  }

  /**
   * Handle updated notification
   */
  onNotificationUpdated(notification) {
    console.log('Notification updated:', notification);
    // Update UI with modified notification
    // Example: updateNotificationInUI(notification)
  }

  /**
   * Handle deleted notification
   */
  onNotificationDestroyed(notificationId) {
    console.log('Notification deleted:', notificationId);
    // Remove notification from UI
    // Example: removeNotificationFromUI(notificationId)
  }

  /**
   * Fetch all notifications via REST API
   */
  async fetchNotifications() {
    try {
      const response = await fetch(`${this.baseUrl}/api/notifications`, {
        headers: {
          'X-User-Id': this.userId,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const notifications = await response.json();
      console.log('Notifications:', notifications);
      return notifications;
    } catch (error) {
      console.error('Error fetching notifications:', error);
      return [];
    }
  }

  /**
   * Create a new notification
   */
  async createNotification(message) {
    try {
      const response = await fetch(`${this.baseUrl}/api/notifications`, {
        method: 'POST',
        headers: {
          'X-User-Id': this.userId,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          notification: {
            message: message,
            read: false
          }
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const notification = await response.json();
      console.log('Notification created:', notification);
      return notification;
    } catch (error) {
      console.error('Error creating notification:', error);
      return null;
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId) {
    try {
      const response = await fetch(
        `${this.baseUrl}/api/notifications/${notificationId}/mark_read`,
        {
          method: 'PATCH',
          headers: {
            'X-User-Id': this.userId,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const notification = await response.json();
      console.log('Notification marked as read:', notification);
      return notification;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return null;
    }
  }

  /**
   * Delete a notification
   */
  async deleteNotification(notificationId) {
    try {
      const response = await fetch(
        `${this.baseUrl}/api/notifications/${notificationId}`,
        {
          method: 'DELETE',
          headers: {
            'X-User-Id': this.userId,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      console.log('Notification deleted');
      return true;
    } catch (error) {
      console.error('Error deleting notification:', error);
      return false;
    }
  }

  /**
   * Get unread notifications count
   */
  async getUnreadCount() {
    try {
      const notifications = await this.fetchNotifications();
      return notifications.filter(n => !n.read).length;
    } catch (error) {
      console.error('Error getting unread count:', error);
      return 0;
    }
  }
}

// Usage Example:
// 
// const client = new NotificationClient(1); // userId = 1
// 
// // Connect to WebSocket
// client.connect();
// 
// // Subscribe to all notification events
// client.subscribe((data) => {
//   console.log('Notification event:', data);
//   // Update your UI here
// });
// 
// // Fetch existing notifications
// client.fetchNotifications();
// 
// // Create a new notification
// client.createNotification('Task comment added');
// 
// // Mark notification as read
// client.markAsRead(1);
// 
// // Delete notification
// client.deleteNotification(1);
// 
// // Get unread count
// client.getUnreadCount();

export default NotificationClient;
