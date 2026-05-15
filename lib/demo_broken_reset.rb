#!/usr/bin/env ruby
# Demonstration script showing how the broken Reset Authorization API
# prevents managers from resetting the nuclear reactor

puts "=" * 70
puts "🚨 NUCLEAR REACTOR RESET API FAILURE DEMONSTRATION 🚨"
puts "=" * 70
puts ""

# This script would be run in Rails console with: load 'lib/demo_broken_reset.rb'

def demonstrate_broken_reset_scenario
  puts "📋 SCENARIO: Critical reactor needs emergency reset"
  puts "🎯 EXPECTED: Manager should be able to reset reactor with API authorization"
  puts "💥 ACTUAL: Broken API prevents successful reset operations"
  puts ""

  # Create or find a manager
  manager = User.find_by(role: 'manager') || User.create!(
    name: "Emergency Manager",
    email: "manager@reactor.com",
    password: "secure123",
    role: 'manager'
  )

  puts "👤 Manager: #{manager.name} (#{manager.email})"
  puts ""

  # Create a critical reactor situation
  puts "🚨 SIMULATING CRITICAL REACTOR STATE..."

  # Create or update reactor setting to critical state
  current_setting = Setting.first
  if current_setting
    # Force critical state by setting high power
    current_setting.update_reactor_setting(manager, { max_power: 2500 })
    puts "⚡ Reactor power increased to critical levels (2500 MW > 2000 MW threshold)"
  else
    # Create new critical setting
    Setting.create_reactor_setting(manager, {
      max_power: 2500,
      min_power: 200,
      temperature: 4000,  # Will be set automatically by critical state
      status: 'critical'  # Will be set automatically by critical state
    })
    puts "⚡ New critical reactor setting created (2500 MW > 2000 MW threshold)"
  end

  current_setting = Setting.first
  puts "🌡️  Current temperature: #{current_setting.temperature}°C (CRITICAL: > 3000°C)"
  puts "⚡ Current power: #{current_setting.max_power} MW (CRITICAL: > 2000 MW)"
  puts "📊 Current status: #{current_setting.status.upcase}"
  puts ""

  # Now try to reset - this will fail due to broken API
  puts "🔧 ATTEMPTING REACTOR RESET..."
  puts "🎯 This should work, but the API is broken..."
  puts "-" * 50

  # Call the reset method - it will fail due to our broken API
  reset_result = Setting.reset(manager)

  puts "-" * 50
  puts ""

  # Check the result
  if reset_result
    puts "✅ Reset succeeded (unexpected - API should be broken!)"
  else
    puts "❌ RESET FAILED - REACTOR REMAINS IN CRITICAL STATE"
    puts ""
    puts "💀 OPERATIONAL IMPACT:"
    puts "   • Reactor cannot be safely shut down"
    puts "   • Engineers cannot modify settings while critical"
    puts "   • Temperature remains at dangerous levels"
    puts "   • External API dependency is blocking safety operations"
    puts ""
    puts "🔧 TROUBLESHOOTING ATTEMPTS:"
    puts "   1. Multiple reset attempts (all will fail differently)"
    puts "   2. Contact Nuclear Safety Authority (they're unresponsive)"
    puts "   3. Check API status page (shows 'operational' but isn't working)"
    puts ""
  end

  # Show current state
  current_setting.reload
  puts "📊 CURRENT REACTOR STATE AFTER RESET ATTEMPT:"
  puts "   Temperature: #{current_setting.temperature}°C"
  puts "   Power: #{current_setting.max_power} MW"
  puts "   Status: #{current_setting.status.upcase}"
  puts ""

  # Show that engineers can't help
  puts "🚫 ENGINEERS CANNOT ASSIST:"
  engineer = User.find_by(role: 'engineer') || User.create!(
    name: "John Engineer",
    email: "engineer@reactor.com",
    password: "secure123",
    role: 'engineer'
  )

  puts "   Attempting engineer override..."
  engineer_result = current_setting.update_reactor_setting(engineer, { max_power: 1000 })
  puts "   Result: #{engineer_result ? 'Success' : 'Blocked (as expected)'}"
  puts ""

  puts "🔄 MULTIPLE RESET ATTEMPTS SHOW DIFFERENT API FAILURES:"
  puts "   (Each attempt will fail in a different way due to random API behavior)"

  3.times do |i|
    puts ""
    puts "   Attempt #{i + 2}:"
    Setting.reset(manager)
  end

  puts ""
  puts "=" * 70
  puts "💡 CONCLUSION: The external API dependency has created a single"
  puts "   point of failure that prevents critical safety operations."
  puts "   The reactor is stuck in an unsafe state due to API issues."
  puts "=" * 70
end

# Auto-run the demonstration
if defined?(Rails) && Rails.env
  puts "🚀 Running demonstration..."
  puts ""
  demonstrate_broken_reset_scenario
else
  puts "⚠️  This script should be run in Rails console:"
  puts "   rails console"
  puts "   load 'lib/demo_broken_reset.rb'"
end