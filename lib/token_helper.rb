require 'jwt'

module TokenHelper
  class << self
    # Generate a token for a user in rails console
    # Usage: TokenHelper.token(User.first)
    def token(user, expires_in: 24.hours)
      AuthenticationService.new(user).generate_token(expires_in: expires_in)
    end

    # Decode and verify a token
    # Usage: TokenHelper.decode("eyJh...")
    def decode(token)
      AuthenticationService.decode_token(token)
    end

    # Create a user and get their token
    # Usage: TokenHelper.user_with_token("john@example.com", "John Doe")
    def user_with_token(email, name = "Test User", expires_in: 24.hours)
      user = User.find_or_create_by(email: email) do |u|
        u.name = name
      end
      token = token(user, expires_in: expires_in)
      
      puts "User: #{user.inspect}"
      puts "Token: #{token}"
      
      [user, token]
    end

    # Create multiple test users with tokens
    # Usage: TokenHelper.setup_test_users
    def setup_test_users
      users = []
      
      3.times do |i|
        email = "user#{i + 1}@example.com"
        user = User.find_or_create_by(email: email) do |u|
          u.name = "Test User #{i + 1}"
        end
        
        user_token = token(user)
        users << { user: user, token: user_token }
        
        puts "Created user #{i + 1}: #{email}"
        puts "  Token: #{user_token[0..50]}..."
      end
      
      users
    end

    # Create notifications for a user
    # Usage: TokenHelper.create_notifications(User.first, 5)
    def create_notifications(user, count = 5)
      notifications = []
      
      count.times do |i|
        notification = user.notifications.create(
          message: "Test notification #{i + 1}: #{Faker::Lorem.sentence}"
        )
        notifications << notification
      end
      
      puts "Created #{notifications.length} notifications for #{user.email}"
      notifications
    end

    # Print curl commands for testing
    # Usage: TokenHelper.curl_examples
    def curl_examples(user = User.first)
      token = token(user)
      puts "\n=== CURL EXAMPLES ==="
      puts "\n1. Get all notifications:"
      puts "curl -H 'Authorization: Bearer #{token[0..30]}...' http://localhost:3000/api/notifications"
      
      puts "\n2. Create notification:"
      puts "curl -X POST http://localhost:3000/api/notifications \\"
      puts "  -H 'Authorization: Bearer #{token[0..30]}...' \\"
      puts "  -H 'Content-Type: application/json' \\"
      puts "  -d '{\"notification\": {\"message\": \"Test\"}}'"
      
      puts "\n3. Mark as read:"
      puts "curl -X PATCH http://localhost:3000/api/notifications/1/mark_read \\"
      puts "  -H 'Authorization: Bearer #{token[0..30]}...'"
      
      puts "\n4. Verify token:"
      puts "curl -H 'Authorization: Bearer #{token[0..30]}...' http://localhost:3000/api/authentication/verify"
    end
  end
end
