# ActionCable WebSocket Integration Guide

## Overview
This notification system uses Rails ActionCable to provide real-time updates via WebSocket connections. Users can receive instant notifications and interact with them in real-time.

## Server-Side Setup

### 1. Database Considerations
The migration file includes:
- `read` boolean field (default: false) for tracking read status
- User foreign key for association
- Indexed on user_id and created_at for query optimization

### 2. ActionCable Configuration

#### Cable Connection (`app/channels/application_cable/connection.rb`)
- Authenticates users based on session user_id
- Identifies connections by `:current_user`
- Rejects unauthorized connections

#### Notifications Channel (`app/channels/notifications_channel.rb`)
Subscribers receive real-time updates for:
- `notification_created`: When a new notification is pushed
- `notification_updated`: When a notification is marked as read or modified
- `notification_destroyed`: When a notification is deleted

### 3. Broadcast Events

The `Notification` model automatically broadcasts via ActionCable callbacks:
```ruby
after_create :broadcast_creation   # Broadcasts to user when new notification created
after_update :broadcast_update     # Broadcasts when notification is modified
after_destroy :broadcast_destruction # Broadcasts when notification is deleted
```

### 4. Routes Configuration
```ruby
namespace :api do
  resources :notifications do
    member do
      patch :mark_read
    end
  end
end

mount ActionCable.server => '/cable'
```

## API Endpoints

### List Notifications
```
GET /api/notifications
Headers: X-User-Id: <user_id>
```

### Create Notification
```
POST /api/notifications
Headers: X-User-Id: <user_id>
Body: {
  "notification": {
    "message": "Task comment added",
    "read": false
  }
}
```

### Get Single Notification
```
GET /api/notifications/:id
Headers: X-User-Id: <user_id>
```

### Mark Notification as Read
```
PATCH /api/notifications/:id/mark_read
Headers: X-User-Id: <user_id>
```

### Update Notification
```
PATCH /api/notifications/:id
Headers: X-User-Id: <user_id>
Body: {
  "notification": {
    "read": true
  }
}
```

### Delete Notification
```
DELETE /api/notifications/:id
Headers: X-User-Id: <user_id>
```

## Client-Side Implementation (JavaScript Example)

### 1. Connect to WebSocket
```javascript
// Using Rails UJS helper
import * as ActionCable from "@rails/actioncable"

const cable = ActionCable.createConsumer("ws://localhost:3000/cable");

// Subscribe to notifications channel
const subscription = cable.subscriptions.create("NotificationsChannel", {
  received(data) {
    console.log("Received from server:", data);
    handleNotificationUpdate(data);
  }
});

function handleNotificationUpdate(data) {
  switch(data.type) {
    case 'notification_created':
      console.log('New notification:', data.notification);
      // Add to UI
      break;
    case 'notification_updated':
      console.log('Notification updated:', data.notification);
      // Update UI
      break;
    case 'notification_destroyed':
      console.log('Notification deleted:', data.notification_id);
      // Remove from UI
      break;
  }
}
```

### 2. RESTful API Calls
```javascript
const userId = 1; // In real app, get from session

// Fetch notifications
fetch('/api/notifications', {
  headers: {
    'X-User-Id': userId
  }
})
.then(res => res.json())
.then(notifications => console.log(notifications));

// Create notification
fetch('/api/notifications', {
  method: 'POST',
  headers: {
    'X-User-Id': userId,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    notification: {
      message: 'New comment on task',
      read: false
    }
  })
})
.then(res => res.json())
.then(notification => console.log(notification));

// Mark as read
fetch(`/api/notifications/${notificationId}/mark_read`, {
  method: 'PATCH',
  headers: {
    'X-User-Id': userId
  }
})
.then(res => res.json())
.then(notification => console.log('Marked as read:', notification));
```

### 3. Using ActionCable Channel Methods
```javascript
// You can also trigger server-side methods on the channel
subscription.send({
  action: 'mark_read',
  id: notificationId
});
```

## Development

### 1. Database Setup
```bash
rails db:migrate
```

### 2. Run Rails Server
```bash
rails server
```

The ActionCable server runs on the same process in development (async adapter).

### 3. Testing Flow

**Terminal 1: Start Rails server**
```bash
rails server
```

**Terminal 2: Use Rails console to trigger notifications**
```bash
rails console
user = User.first
notification = user.notifications.create(message: "Test notification")
# This will broadcast to all connected clients via WebSocket
```

## Production Configuration

For production, update `config/cable.yml`:
```yaml
production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

## Security Considerations

1. **User Authentication**: The connection validates users in `ApplicationCable::Connection`
2. **Authorization**: Each notification is scoped to the current user
3. **CORS**: Configure if frontend is on different domain
4. **Header-based Auth**: Uses `X-User-Id` header for identifying users

## Scopes and Queries

The model includes useful scopes:
```ruby
Notification.unread      # Get unread notifications
Notification.read        # Get read notifications
current_user.notifications # Get user's notifications
```

## Broadcasting Formats

### Notification Created
```json
{
  "type": "notification_created",
  "notification": {
    "id": 1,
    "user_id": 1,
    "message": "Task comment added",
    "read": false,
    "created_at": "2026-02-17T14:00:00Z",
    "updated_at": "2026-02-17T14:00:00Z"
  }
}
```

### Notification Updated
```json
{
  "type": "notification_updated",
  "notification": {
    "id": 1,
    "user_id": 1,
    "message": "Task comment added",
    "read": true,
    "created_at": "2026-02-17T14:00:00Z",
    "updated_at": "2026-02-17T14:00:01Z"
  }
}
```

### Notification Destroyed
```json
{
  "type": "notification_destroyed",
  "notification_id": 1
}
```
