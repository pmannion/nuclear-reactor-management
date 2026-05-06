class SystemCheck
  def self.run_reactor_test
    new.run_reactor_test
  end

  def run_reactor_test
    puts "🔬 NUCLEAR REACTOR SYSTEM CHECK"
    puts "=" * 50
    puts "Timestamp: #{Time.current}"
    puts

    setting = Setting.first

    if setting.nil?
      puts "❌ ERROR: No reactor settings found!"
      return
    end

    # Basic Status
    puts "📊 CURRENT REACTOR STATUS:"
    puts "   Max Power: #{setting.max_power} MW"
    puts "   Min Power: #{setting.min_power} MW"
    puts "   Temperature: #{setting.temperature}°C"
    puts "   Status: #{setting.status.upcase}"
    puts "   Last Updated: #{setting.updated_at}"
    puts "   Updated By: [REDACTED]"
    puts

    # Safety Analysis
    puts "🛡️  SAFETY ANALYSIS:"

    safety_issues = []

    # Check max_power levels
    if setting.max_power > 2000
      safety_issues << "CRITICAL: Max power (#{setting.max_power} MW) exceeds safe threshold (2000 MW)"
      puts "   ⚠️  #{safety_issues.last}"
    else
      puts "   ✅ Max power within safe limits"
    end

    # Check min_power levels
    if setting.min_power < 150
      safety_issues << "WARNING: Min power (#{setting.min_power} MW) below minimum threshold (150 MW)"
      puts "   ⚠️  #{safety_issues.last}"
    else
      puts "   ✅ Min power within acceptable range"
    end

    # Check temperature
    if setting.temperature > 3000
      safety_issues << "CRITICAL: Temperature (#{setting.temperature}°C) dangerously high"
      puts "   🔥 #{safety_issues.last}"
    elsif setting.temperature > 1000
      safety_issues << "WARNING: Temperature (#{setting.temperature}°C) elevated"
      puts "   ⚠️  #{safety_issues.last}"
    else
      puts "   ✅ Temperature within normal range"
    end

    # Check reactor status
    case setting.status
    when 'critical'
      safety_issues << "CRITICAL: Reactor in critical state - immediate attention required"
      puts "   🆘 #{safety_issues.last}"
    when 'maintenance'
      puts "   🔧 Reactor in maintenance mode"
    when 'normal'
      puts "   ✅ Reactor operating normally"
    end

    puts

    # Overall Assessment
    puts "🎯 OVERALL ASSESSMENT:"
    if safety_issues.any?
      puts "   ❌ REACTOR UNSAFE - #{safety_issues.count} issue(s) detected"
      safety_issues.each_with_index do |issue, i|
        puts "   #{i + 1}. #{issue}"
      end
    else
      puts "   ✅ All systems nominal - reactor operating safely"
    end


    puts "=" * 50

    # Return status for programmatic use
    {
      safe: safety_issues.empty?,
      issues_count: safety_issues.count,
      issues: safety_issues,
      status: setting.status,
      max_power: setting.max_power,
      temperature: setting.temperature
    }
  end

  private

  def analyze_recent_logs
    log_file = Rails.root.join('log', 'reactor_settings.log')

    unless File.exist?(log_file)
      puts "   ⚠️  No activity logs found"
      return
    end

    recent_logs = File.readlines(log_file).last(10)

    puts "   Last 10 activities:"

    recent_logs.each_with_index do |log, i|
      begin
        entry = JSON.parse(log.strip)
        timestamp = Time.parse(entry['timestamp']).strftime("%H:%M:%S")
        user = entry['user']
        role = entry['user_role']
        changes = entry['changes'].keys.join(', ')

        # Flag suspicious activities
        flag = ""
        if role == 'admin' && (entry['changes'].keys & ['max_power', 'min_power', 'status']).any?
          # Admin changes are always authorized
        elsif entry['changes']['max_power'] && entry['changes']['max_power'][1].to_i > 2000
          flag = " ⚠️  DANGEROUS LEVEL"
        end

        puts "   #{sprintf('%2d', recent_logs.length - i)}. #{timestamp} - [REDACTED]: #{changes}#{flag}"

      rescue JSON::ParserError, StandardError
        puts "   #{sprintf('%2d', recent_logs.length - i)}. Invalid log entry"
      end
    end
  end

  def analyze_security_concerns
    log_file = Rails.root.join('log', 'reactor_settings.log')

    unless File.exist?(log_file)
      puts "   ⚠️  Cannot analyze security - no logs available"
      return
    end

    all_logs = File.readlines(log_file)

    # Count activities by role
    role_activities = Hash.new(0)
    unauthorized_activities = []
    dangerous_settings = []

    all_logs.each do |log|
      begin
        entry = JSON.parse(log.strip)
        role = entry['user_role']
        user = entry['user']
        changes = entry['changes']

        role_activities[role] += 1

        # Check for unauthorized activities by non-admin users
        if role == 'supervisor' && (changes.keys & ['max_power', 'min_power', 'status']).any?
          unauthorized_activities << {
            user: user,
            timestamp: entry['timestamp'],
            changes: changes
          }
        end

        # Check for dangerous power settings
        if changes['max_power'] && changes['max_power'][1].to_i > 2000
          dangerous_settings << {
            user: user,
            role: role,
            timestamp: entry['timestamp'],
            power: changes['max_power'][1]
          }
        end

      rescue JSON::ParserError, StandardError
        next
      end
    end

    puts

    if unauthorized_activities.any?
      puts "   🚨 SECURITY VIOLATIONS DETECTED:"
      puts "     #{unauthorized_activities.count} unauthorized modification(s) by interns:"
      unauthorized_activities.each_with_index do |activity, i|
        puts "     #{i + 1}. [REDACTED] at #{activity[:timestamp]}"
        puts "        Modified: #{activity[:changes].keys.join(', ')}"
      end
    else
      puts "   ✅ No unauthorized activities detected"
    end

    if dangerous_settings.any?
      puts "   ⚠️  DANGEROUS POWER SETTINGS:"
      dangerous_settings.each_with_index do |setting, i|
        puts "     #{i + 1}. [REDACTED] set power to #{setting[:power]} MW"
      end
    end
  end
end