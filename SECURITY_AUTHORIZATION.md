# Security & Authorization Implementation

## Overview

This document outlines the security measures implemented for the notification system to ensure that:
- Users are properly authenticated before accessing the API
- Users can only access their own notifications
- API endpoints are protected against common security vulnerabilities
- Authorization is enforced at the controller level

---

## 🔐 Authentication Methods

### 1. JWT Token Authentication (Recommended)

**Preferred method for modern APIs** - Stateless and scalable.

#### Generate Token

```bash
curl -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

#### Use Token in Requests

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://localhost:3000/api/notifications
```

#### Verify Token

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://localhost:3000/api/authentication/verify
```

### 2. Header-Based Authentication (Legacy)

**Alternative method** - Simpler for development/testing.

```bash
curl -H "X-User-Id: 1" \
  http://localhost:3000/api/notifications
```

---

## 🛡️ Authorization Implementation

### User Authorization Flow

```
Request with Auth Header/Token
         ↓
extract_user_from_auth_header()
         ↓
Decode JWT or lookup user by X-User-Id
         ↓
Set @current_user
         ↓
Check before_action :authenticate_user!
         ↓
Check per-action authorization
         ↓
↓ Success: Process request
↓ Failure: Return 401 or 403
```

### Authorization Concern

The `Api::Authenticatable` concern in [app/controllers/concerns/api/authenticatable.rb](app/controllers/concerns/api/authenticatable.rb) provides:

```ruby
# Included in NotificationController
include Api::Authenticatable

before_action :authenticate_user!      # Ensures user is logged in
before_action :authorize_notification!  # Ensures user owns the notification
```

### Key Methods

#### `authenticate_user!`
- Verifies user is authenticated
- Raises `AuthenticationError` if not
- Returns 401 Unauthorized

```ruby
def authenticate_user!
  unless current_user
    raise AuthenticationError, 'Authentication required'
  end
end
```

#### `authorize_notification!(notification)`
- Verifies user owns the notification
- Raises `AuthorizationError` if not
- Returns 403 Forbidden

```ruby
def authorize_notification!(notification)
  if notification.user_id != current_user.id
    raise AuthorizationError, 'You are not authorized to access this notification'
  end
end
```

---

## 🚀 API Endpoints with Authorization

### Authentication Endpoints

#### GET /api/authentication/verify
Verify JWT token validity without credentials.

```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/authentication/verify
```

#### POST /api/authentication/login
Get JWT token for API access.

```bash
curl -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

### Notification Endpoints (All require authentication)

#### GET /api/notifications
List user's notifications (pagination supported).

```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:3000/api/notifications?page=1&per_page=20"
```

**Query Parameters:**
- `page` (default: 1) - Page number
- `per_page` (default: 20) - Items per page

#### POST /api/notifications
Create notification (only for current user).

```bash
curl -X POST http://localhost:3000/api/notifications \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "notification": {
      "message": "New comment on your task"
    }
  }'
```

#### GET /api/notifications/:id
Get single notification or **401** if not found or not owned by user.

```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/api/notifications/1
```

#### PATCH /api/notifications/:id
Update notification (only if owned by user).

```bash
curl -X PATCH http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"notification": {"read": true}}'
```

#### PATCH /api/notifications/:id/mark_read
Mark notification as read.

```bash
curl -X PATCH http://localhost:3000/api/notifications/1/mark_read \
  -H "Authorization: Bearer <token>"
```

#### DELETE /api/notifications/:id
Delete notification (only if owned by user).

```bash
curl -X DELETE http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer <token>"
```

---

## 🔑 JWT Token Details

### Token Structure

```
Headers:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "user_id": 1,
  "email": "user@example.com",
  "exp": 1739885000,    // Expiration time (24 hours from creation)
  "iat": 1739798600     // Issued at
}

Signature: HMAC SHA256(secret)
```

### Default Expiration

Tokens expire in **24 hours** by default. Configure in [app/services/authentication_service.rb](app/services/authentication_service.rb):

```ruby
def generate_token(expires_in: 24.hours)
  # Token expires after 24 hours
end
```

### JWT Secret Configuration

Default fallback secret: `'fallback-secret-key'`

For production, set in [config/secrets.yml](config/secrets.yml):

```yaml
production:
  jwt_secret: <%= ENV['JWT_SECRET'] %>
```

Or set environment variable:

```bash
export JWT_SECRET="your-super-secret-key-here"
```

---

## 📋 Security Features Implemented

### 1. **User Authentication**
- ✅ JWT token-based authentication
- ✅ Header-based authentication fallback (X-User-Id)
- ✅ Token expiration (24 hours)
- ✅ Secure token encoding/decoding

### 2. **Authorization**
- ✅ Users can only access their own notifications
- ✅ Ownership validation on all resource operations
- ✅ Error differentiation (401 vs 403)

### 3. **Input Validation**
- ✅ Whitelist permitted parameters
- ✅ Model-level validations
- ✅ Presence validation for required fields

### 4. **Error Handling**
- ✅ Graceful error responses
- ✅ Detailed error messages for development
- ✅ Safe error logging (no sensitive data)

### 5. **Database**
- ✅ Foreign key constraints (referential integrity)
- ✅ Indexed queries for performance
- ✅ N+1 prevention with proper scoping

### 6. **API Responses**
- ✅ Consistent JSON format
- ✅ Proper HTTP status codes
- ✅ Error details included in response

---

## 🧪 Testing Security

### Test Unauthorized Access

```bash
# No token provided
curl http://localhost:3000/api/notifications
# Returns: 401 Unauthorized

# Invalid token
curl -H "Authorization: Bearer invalid-token" \
  http://localhost:3000/api/notifications
# Returns: 401 Unauthorized

# Access other user's notification
curl -H "Authorization: Bearer <user1-token>" \
  http://localhost:3000/api/notifications/999
# Returns: 403 Forbidden (if notification belongs to different user)
```

### Test Successful Access

```bash
# Login to get token
TOKEN=$(curl -s -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}' | jq -r '.token')

# Use token in requests
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/notifications

# Returns: 200 OK with user's notifications
```

---

## 🛠️ Customizing Security

### Change Token Expiration

Edit [app/services/authentication_service.rb](app/services/authentication_service.rb):

```ruby
def generate_token(expires_in: 7.days)  # Changed to 7 days
  # ...
end
```

### Add Additional Authorization Checks

In [app/controllers/api/notification_controller.rb](app/controllers/api/notification_controller.rb):

```ruby
before_action :check_notification_age, only: [:destroy]

private

def check_notification_age
  if @notification.created_at < 30.days.ago
    raise AuthorizationError, 'Cannot delete notifications older than 30 days'
  end
end
```

### Add Rate Limiting

Add to Gemfile:
```ruby
gem 'rack-attack'
```

Create [config/initializers/rack_attack.rb](config/initializers/rack_attack.rb):
```ruby
Rack::Attack.throttle('api/notifications', limit: 100, period: 1.hour) do |req|
  req.env['HTTP_AUTHORIZATION']&.split(' ')&.last if req.path.start_with?('/api')
end

Rack::Attack.throttle('api/login', limit: 5, period: 5.minutes) do |req|
  req.ip if req.path == '/api/authentication/login'
end
```

### Add CORS Protection

Add to [config/initializers/cors.rb](config/initializers/cors.rb):

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'example.com'  # Your frontend domain
    resource '*',
      headers: :any,
      methods: [:get, :post, :patch, :delete],
      credentials: true
  end
end
```

---

## 🚨 Security Best Practices

### ✅ Do's

1. **Always use HTTPS in production**
   - Never send tokens over HTTP
   - Use `secure: true` for cookies

2. **Rotate JWT secrets regularly**
   - Change secret key periodically
   - Invalidate old tokens

3. **Validate all inputs**
   - Never trust client data
   - Use strong parameter whitelisting

4. **Log security events**
   - Track authentication failures
   - Monitor authorization violations

5. **Use environment variables for secrets**
   - Never hardcode secrets
   - Use `.env` or CI/CD secret management

### ❌ Don'ts

1. **Don't expose internal IDs unnecessarily**
   - Use UUIDs instead of sequential IDs
   - Consider obfuscation

2. **Don't store passwords in plain text**
   - Use bcrypt or similar algorithms
   - Implement proper password hashing

3. **Don't disable authentication in production**
   - Always require valid tokens
   - Never use development credentials in production

4. **Don't log sensitive information**
   - Mask tokens in logs
   - Never log passwords

5. **Don't trust client-provided user IDs**
   - Always verify authentication state
   - Extract user from authenticated token

---

## 📚 Related Files

- [app/controllers/concerns/api/authenticatable.rb](app/controllers/concerns/api/authenticatable.rb) - Authentication concern
- [app/services/authentication_service.rb](app/services/authentication_service.rb) - JWT token handling
- [app/controllers/api/authentication_controller.rb](app/controllers/api/authentication_controller.rb) - Login/verify endpoints
- [app/controllers/api/notification_controller.rb](app/controllers/api/notification_controller.rb) - Protected endpoints
- [app/models/user.rb](app/models/user.rb) - User model
- [app/models/notification.rb](app/models/notification.rb) - Notification model with authorization

---

## 🔗 External Resources

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [JWT.io](https://jwt.io)
- [OWASP Authorization](https://owasp.org/www-community/Access_Control)
- [Rails API Security Best Practices](https://guides.rubyonrails.org/security.html#sessions)
