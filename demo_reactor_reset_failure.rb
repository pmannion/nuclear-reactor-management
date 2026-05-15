#!/usr/bin/env ruby
# Standalone demonstration of the broken reactor reset API
# Run with: rails runner demo_reactor_reset_failure.rb

puts "=" * 70
puts "🚨 NUCLEAR REACTOR RESET API FAILURE DEMONSTRATION 🚨"
puts "=" * 70
puts ""

puts "📋 SCENARIO OVERVIEW:"
puts "• Nuclear reactor enters critical state (> 2000 MW)"
puts "• Only managers can perform emergency reset"
puts "• Reset now requires external API authorization"
puts "• The API is broken and returns inconsistent/wrong data"
puts "• This prevents successful reactor resets"
puts ""

# Create test data
puts "🏗️  SETTING UP TEST SCENARIO..."

manager = User.find_by(role: 'manager')
unless manager
  manager = User.create!(
    name: "Emergency Manager Sarah",
    email: "sarah.manager@reactor.com",
    password: "secure123",
    role: 'manager'
  )
  puts "✅ Created manager: #{manager.name}"
else
  puts "✅ Using existing manager: #{manager.name}"
end

engineer = User.find_by(role: 'engineer')
unless engineer
  engineer = User.create!(
    name: "John Engineer",
    email: "john.engineer@reactor.com",
    password: "secure123",
    role: 'engineer'
  )
  puts "✅ Created engineer: #{engineer.name}"
else
  puts "✅ Using existing engineer: #{engineer.name}"
end

puts ""

# Create critical reactor state
puts "🚨 CREATING CRITICAL REACTOR STATE..."

# Delete existing settings to start fresh
Setting.destroy_all

# Create normal setting first
setting = Setting.create_reactor_setting(manager, {
  max_power: 1800,
  min_power: 200,
  temperature: 650,
  status: 'normal'
})

puts "📊 Initial state: #{setting.max_power} MW, #{setting.temperature}°C, #{setting.status}"

# Trigger critical state by exceeding power threshold
puts "⚡ Increasing power beyond safe limits..."
setting.update_reactor_setting(manager, { max_power: 2500 })

setting.reload
puts "🚨 CRITICAL STATE TRIGGERED:"
puts "   Power: #{setting.max_power} MW (> 2000 MW threshold)"
puts "   Temperature: #{setting.temperature}°C (auto-set to critical level)"
puts "   Status: #{setting.status}"
puts ""

# Show that engineers are blocked
puts "🚫 VERIFYING ENGINEER LOCKOUT..."
engineer_result = setting.update_reactor_setting(engineer, { max_power: 1000 })
puts "   Engineers cannot modify critical reactor: #{engineer_result ? 'Failed - allowed' : 'Confirmed - blocked'}"
puts ""

# Now demonstrate the broken reset API
puts "🔧 ATTEMPTING MANAGER RESET (WILL FAIL DUE TO BROKEN API)..."
puts "=" * 50

# This will call our broken API and fail
reset_result = Setting.reset(manager)

puts "=" * 50
puts ""

# Check final state
setting.reload
puts "📊 FINAL REACTOR STATE:"
puts "   Power: #{setting.max_power} MW"
puts "   Temperature: #{setting.temperature}°C"
puts "   Status: #{setting.status}"
puts "   Reset successful: #{reset_result ? 'YES' : 'NO'}"
puts ""

if reset_result
  puts "😱 UNEXPECTED: Reset succeeded despite broken API!"
else
  puts "💀 CRITICAL SITUATION: Reactor stuck in unsafe state"
  puts ""
  puts "🚨 OPERATIONAL IMPACT:"
  puts "   • Reactor cannot be safely reset due to API dependency"
  puts "   • Engineers locked out while in critical state"
  puts "   • External API is returning incorrect authorization data"
  puts "   • Safety systems compromised by unreliable third-party service"
  puts ""

  puts "🔄 ATTEMPTING MULTIPLE RESETS (showing different API failures):"
  puts ""

  # Show multiple different failures
  3.times do |i|
    puts "   Reset attempt #{i + 2}:"
    puts "   " + "-" * 40
    attempt_result = Setting.reset(manager)
    puts "   Result: #{attempt_result ? 'Success' : 'Failed'}"
    puts ""
  end
end

puts "=" * 70
puts "💡 DEMONSTRATION COMPLETE"
puts ""
puts "KEY FINDINGS:"
puts "• External API dependency creates single point of failure"
puts "• Broken API prevents critical safety operations"
puts "• System becomes unsafe when third-party service is unreliable"
puts "• No fallback mechanism for emergency situations"
puts "=" * 70