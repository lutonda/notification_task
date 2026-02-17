# Quick Start Guide - Notification API

## 🚀 Getting Started

### 1. Setup Database

```bash
rails db:create
rails db:migrate
```

### 2. Create Test User

```bash
rails console

user = User.create!(
  name: "John Doe",
  email: "john@example.com"
)

# Create some notifications
user.notifications.create!(message: "Task comment added")
user.notifications.create!(message: "Someone mentioned you")
```

### 3. Get Authorization Token

```bash
curl -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "john@example.com"}'
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

Save the token for use in subsequent requests.

---

## 📋 Common API Operations

### Get All Notifications

```bash
TOKEN="your-token-here"

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/notifications
```

### Create Notification

```bash
curl -X POST http://localhost:3000/api/notifications \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notification": {
      "message": "New task assigned to you"
    }
  }'
```

### Mark Notification as Read

```bash
curl -X PATCH http://localhost:3000/api/notifications/1/mark_read \
  -H "Authorization: Bearer $TOKEN"
```

### Delete Notification

```bash
curl -X DELETE http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Verify Token

```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/authentication/verify
```

---

## 🔌 WebSocket Real-Time Updates

### JavaScript Client

```javascript
// Install @rails/actioncable if needed
// npm install @rails/actioncable

import * as ActionCable from '@rails/actioncable';

// Connect to WebSocket
const cable = ActionCable.createConsumer('ws://localhost:3000/cable');

// Subscribe to notifications
const subscription = cable.subscriptions.create('NotificationsChannel', {
  received(data) {
    console.log('Notification update:', data);
    
    switch(data.type) {
      case 'notification_created':
        console.log('New notification:', data.notification);
        break;
      case 'notification_updated':
        console.log('Notification updated:', data.notification);
        break;
      case 'notification_destroyed':
        console.log('Notification deleted:', data.notification_id);
        break;
    }
  }
});
```

---

## 📊 Pagination

Get notifications with pagination:

```bash
# Page 1, 20 items per page (default)
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/notifications?page=1&per_page=20"

# Page 2, 10 items per page
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/notifications?page=2&per_page=10"
```

---

## 🧪 Test the Full Flow

```bash
#!/bin/bash

# 1. Start Rails server
rails server &
SERVER_PID=$!

# Wait for server to start
sleep 2

# 2. Get token
TOKEN=$(curl -s -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "john@example.com"}' | jq -r '.token')

echo "Token: $TOKEN"

# 3. Create notification
curl -s -X POST http://localhost:3000/api/notifications \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notification": {"message": "Test notification"}}' | jq '.'

# 4. List notifications
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/notifications | jq '.'

# 5. Mark first notification as read
curl -s -X PATCH http://localhost:3000/api/notifications/1/mark_read \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Cleanup
kill $SERVER_PID
```

---

## 🐛 Troubleshooting

### No Token Provided Error
- Make sure you're including the Authorization header with Bearer token
- Check that the token is valid (not expired)

### Unauthorized (401)
- Token may have expired (24 hours)
- Request a new token via login endpoint

### Forbidden (403)
- You're trying to access another user's notification
- Each user can only see their own notifications

### Notification Not Found
- Notification may have been deleted
- Double-check the notification ID

---

## 📚 Documentation Files

- [ACTIONCABLE_INTEGRATION.md](ACTIONCABLE_INTEGRATION.md) - WebSocket real-time updates
- [SECURITY_AUTHORIZATION.md](SECURITY_AUTHORIZATION.md) - Authentication & Authorization details
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Complete implementation overview

---

## 🔗 API Reference

### Authentication Endpoints
- `POST /api/authentication/login` - Get JWT token
- `GET /api/authentication/verify` - Verify token validity

### Notification Endpoints
- `GET /api/notifications` - List notifications (paginated)
- `POST /api/notifications` - Create notification
- `GET /api/notifications/:id` - Get single notification
- `PATCH /api/notifications/:id` - Update notification
- `PATCH /api/notifications/:id/mark_read` - Mark as read
- `DELETE /api/notifications/:id` - Delete notification

### WebSocket
- Mount point: `/cable`
- Channel: `NotificationsChannel`
- Events: notification_created, notification_updated, notification_destroyed

---

## ✅ Features Included

- ✅ JWT token authentication
- ✅ User authorization (own notifications only)
- ✅ Real-time updates via WebSocket/ActionCable
- ✅ REST API with pagination
- ✅ Error handling with proper status codes
- ✅ Database optimization (indexed queries)
- ✅ Comprehensive test suite
- ✅ Full documentation

---

## 🚀 Next Steps

1. **Run the test suite**
   ```bash
   rails test
   ```

2. **Build your frontend** to consume the API

3. **Deploy to production** (update JWT secret)

4. **Monitor real-time performance** with WebSocket connections

For more details, see [SECURITY_AUTHORIZATION.md](SECURITY_AUTHORIZATION.md) and [ACTIONCABLE_INTEGRATION.md](ACTIONCABLE_INTEGRATION.md).
