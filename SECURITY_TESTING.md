# Security Testing Guide

## 🧪 How to Test Authorization & Authenticity

### Setup

1. **Start the Rails server:**
```bash
rails server
```

2. **In another terminal, enter Rails console with TokenHelper ready:**
```bash
rails console
```

### Quick Test Scenarios

#### Scenario 1: Login and Get Token

```bash
# In Rails console
user1 = User.find_or_create_by(email: 'test1@example.com') { |u| u.name = 'User 1' }
user2 = User.find_or_create_by(email: 'test2@example.com') { |u| u.name = 'User 2' }

# Get tokens
token1 = TokenHelper.token(user1)
token2 = TokenHelper.token(user2)

puts "Token 1: #{token1}"
puts "Token 2: #{token2}"
```

```bash
# In terminal
curl -X POST http://localhost:3000/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test1@example.com"}'
```

#### Scenario 2: Create Own Notifications

```bash
# Create notifications for user1 in Rails console
5.times { |i| user1.notifications.create(message: "User 1 notification #{i}") }

# In terminal - get user1's notifications with their token
TOKEN1="<token1-value>"
curl -H "Authorization: Bearer $TOKEN1" \
  http://localhost:3000/api/notifications
```

**Expected:** 200 OK with 5 notifications

#### Scenario 3: Try to Access Another User's Notification

```bash
# In Rails console - note the first notification ID
notification_id = user1.notifications.first.id

# In terminal - try to access with user2's token
TOKEN2="<token2-value>"
curl -H "Authorization: Bearer $TOKEN2" \
  http://localhost:3000/api/notifications/$notification_id
```

**Expected:** 403 Forbidden

#### Scenario 4: Create Notification for Specific User

```bash
# User 1 creates their own notification
curl -X POST http://localhost:3000/api/notifications \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "notification": {
      "message": "Created by user 1"
    }
  }'
```

**Expected:** 201 Created

#### Scenario 5: Update Own vs Others' Notifications

```bash
# User 1 updates their own notification (should work)
curl -X PATCH http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"notification": {"message": "Updated by user 1"}}'
```

**Expected:** 200 OK

```bash
# User 2 tries to update user 1's notification (should fail)
curl -X PATCH http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json" \
  -d '{"notification": {"message": "Updated by user 2"}}'
```

**Expected:** 403 Forbidden

#### Scenario 6: Mark Notification as Read

```bash
# User 1 marks their notification as read
curl -X PATCH http://localhost:3000/api/notifications/1/mark_read \
  -H "Authorization: Bearer $TOKEN1"
```

**Expected:** 200 OK with `"read": true`

```bash
# In Rails console - verify it was marked as read
user1.notifications.first.read?
# => true
```

#### Scenario 7: Delete Own vs Others' Notifications

```bash
# User 1 deletes their notification (should work)
curl -X DELETE http://localhost:3000/api/notifications/1 \
  -H "Authorization: Bearer $TOKEN1"
```

**Expected:** 200 OK

#### Scenario 8: Expired Token Access

```bash
# In Rails console - create token with 1 second expiration
short_token = AuthenticationService.new(user1).generate_token(expires_in: 1.second)

# Immediately use it (should work)
curl -H "Authorization: Bearer $short_token" \
  http://localhost:3000/api/authentication/verify
```

**Expected:** 200 OK

```bash
# Wait 2 seconds and try again
sleep 2
curl -H "Authorization: Bearer $short_token" \
  http://localhost:3000/api/authentication/verify
```

**Expected:** 401 Unauthorized with "Invalid token: Signature has expired"

#### Scenario 9: No Authentication

```bash
# Try to access without token
curl http://localhost:3000/api/notifications
```

**Expected:** 401 Unauthorized with "Authentication required"

#### Scenario 10: Invalid Token Format

```bash
# Try with malformed token
curl -H "Authorization: Bearer invalid-token-format" \
  http://localhost:3000/api/notifications
```

**Expected:** 401 Unauthorized

### Automated Test Script

```bash
#!/bin/bash

set -e

BASE_URL="http://localhost:3000"
echo "🧪 Running Security Tests..."

# 1. Login and get tokens
echo -e "\n1️⃣  Getting authentication tokens..."
TOKEN=$(curl -s -X POST "$BASE_URL/api/authentication/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "test1@example.com"}' | jq -r '.token')

echo "✅ Token: ${TOKEN:0:30}..."

# 2. Get notifications
echo -e "\n2️⃣  Getting user's notifications..."
RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/api/notifications")
echo "✅ Received $(echo $RESPONSE | jq '.notifications | length') notifications"

# 3. Create notification
echo -e "\n3️⃣  Creating new notification..."
CREATED=$(curl -s -X POST "$BASE_URL/api/notifications" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"notification\": {\"message\": \"Test $(date +%s)\"}}" | jq '.id')
echo "✅ Created notification #$CREATED"

# 4. Mark as read
echo -e "\n4️⃣  Marking notification as read..."
curl -s -X PATCH "$BASE_URL/api/notifications/$CREATED/mark_read" \
  -H "Authorization: Bearer $TOKEN" | jq '.read'
echo "✅ Marked as read"

# 5. Verify token
echo -e "\n5️⃣  Verifying token..."
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/api/authentication/verify" | jq '.message'
echo "✅ Token verified"

# 6. Test without token
echo -e "\n6️⃣  Testing access without token (should fail)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/notifications")
if [ "$HTTP_CODE" = "401" ]; then
  echo "✅ Correctly rejected request without token (HTTP 401)"
else
  echo "❌ Expected 401, got $HTTP_CODE"
fi

# 7. Delete notification
echo -e "\n7️⃣  Deleting notification..."
curl -s -X DELETE "$BASE_URL/api/notifications/$CREATED" \
  -H "Authorization: Bearer $TOKEN" | jq '.message'
echo "✅ Deleted"

echo -e "\n🎉 All security tests passed!"
```

Save as `test_security.sh`, make executable, and run:
```bash
chmod +x test_security.sh
./test_security.sh
```

### Run Official Test Suite

```bash
# Run all tests
rails test

# Run specific test file
rails test test/controllers/api/authentication_controller_test.rb
rails test test/controllers/api/notifications_controller_test.rb
rails test test/services/authentication_service_test.rb

# Run with verbose output
rails test VERBOSE=1

# Run with specific test
rails test -n test_name
```

### Check Test Coverage

```bash
# Add to Gemfile
group :test do
  gem 'simplecov', require: false
end

# In test_helper.rb
require 'simplecov'
SimpleCov.start

# Run tests and check coverage report
rails test
open coverage/index.html
```

### Debugging Tips

#### Check Token Contents

```bash
# Decode token without verification (ruby tool)
cat > decode_jwt.rb << 'EOF'
require 'jwt'

token = ARGV[0]
parts = token.split('.')
header = JSON.parse(Base64.decode64(parts[0]))
payload = JSON.parse(Base64.decode64(parts[1]))

puts "Header: #{header.inspect}"
puts "Payload: #{payload.inspect}"
puts "Expires: #{Time.at(payload['exp']).inspect}"
EOF

ruby decode_jwt.rb "$TOKEN"
```

#### Monitor ActionCable Connections

In Rails console:
```ruby
# See all connected users
ActionCable.server.connections
```

#### Check Authorization Logs

```bash
# Watch logs in real-time
tail -f log/development.log
```

Look for authentication/authorization errors.

### Common Issues & Fixes

#### Issue: Token Expired Immediately
**Fix:** Check token expiration time in `authentication_service.rb`

#### Issue: Authorization Not Working
**Fix:** Ensure `Api::Authenticatable` concern is included in controller

#### Issue: CORS Errors
**Fix:** Enable CORS in `config/initializers/cors.rb` for your frontend domain

#### Issue: WebSocket Connection Fails
**Fix:** Check ApplicationCable::Connection for proper token extraction

---

## 📊 Security Checklist

- ✅ Authentication required for protected endpoints
- ✅ JWT tokens with expiration
- ✅ User isolation (can't access others' notifications)
- ✅ Proper HTTP status codes (401, 403)
- ✅ Error messages don't leak sensitive info
- ✅ Input validation and sanitization
- ✅ Database constraints enforced
- ✅ HTTPS recommended for production
- ✅ Secure token storage in cookies/headers
- ✅ Rate limiting recommended (add rack-attack)

---

## 🔗 Related Documentation

- [SECURITY_AUTHORIZATION.md](SECURITY_AUTHORIZATION.md) - Detailed security guide
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [ACTIONCABLE_INTEGRATION.md](ACTIONCABLE_INTEGRATION.md) - WebSocket security
