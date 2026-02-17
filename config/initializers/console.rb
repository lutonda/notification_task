if defined?(Rails::Console)
  require_relative '../../lib/token_helper'
  
  puts "\n🔐 Token Helper loaded!"
  puts "Use TokenHelper.help for available commands"
  puts "Examples:"
  puts "  - TokenHelper.user_with_token('user@email.com', 'John Doe')"
  puts "  - TokenHelper.setup_test_users"
  puts "  - TokenHelper.create_notifications(User.first, 5)"
  puts "  - TokenHelper.curl_examples(User.first)"
  puts "  - TokenHelper.decode(token_string)\n"
end
