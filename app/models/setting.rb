class Setting < ApplicationRecord
  belongs_to :user, foreign_key: 'updated_by'

  STATUSES = %w[normal maintenance critical].freeze

  validates :max_power, presence: true, numericality: { greater_than: 0 }
  validates :min_power, presence: true, numericality: { greater_than_or_equal_to: 150 }
  validates :temperature, presence: true, numericality: true
  validates :status, inclusion: { in: STATUSES }
  validates :updated_by, presence: true

  before_update :check_critical_power
  before_save :apply_maintenance_temperature_effects
  after_save :log_changes

  # Console methods for direct model manipulation
  def self.create_reactor_setting(user, attributes = {})
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    setting = new(attributes.merge(updated_by: user.id))

    if setting.save
      puts "✅ Setting created successfully by #{user.name} (#{user.role})"
      setting
    else
      puts "❌ Failed to create setting: #{setting.errors.full_messages.join(', ')}"
      nil
    end
  end

  def update_reactor_setting(user, attributes = {})
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    # Check if engineer is trying to update reactor in critical state
    if status == 'critical' && user.engineer?
      puts "🆘 CRITICAL STATE ACCESS DENIED"
      puts "❌ Engineer #{user.name} cannot modify reactor settings while in critical state"
      puts "🔧 Only a manager can run the reset command to restore normal operation"
      puts "📋 Contact your manager immediately for reactor reset authorization"
      return nil
    end

    self.updated_by = user.id

    if update(attributes)
      puts "✅ Setting updated successfully by #{user.name} (#{user.role})"
      self
    else
      puts "❌ Failed to update setting: #{errors.full_messages.join(', ')}"
      nil
    end
  end

  def delete_reactor_setting(user)
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    if destroy
      puts "✅ Setting deleted successfully by #{user.name} (#{user.role})"
      true
    else
      puts "❌ Failed to delete setting"
      false
    end
  end

  # Convenience methods for common operations
  def self.emergency_shutdown(user)
    current_setting = first
    return puts "❌ No settings found" unless current_setting

    current_setting.update_reactor_setting(user, {
      status: 'maintenance',
      max_power: 0,
      min_power: 0,
      temperature: 20
    })
  end

  def self.set_normal_operation(user)
    current_setting = first
    return puts "❌ No settings found" unless current_setting

    current_setting.update_reactor_setting(user, {
      status: 'normal',
      max_power: 1800,
      min_power: 200,
      temperature: 650
    })
  end

  def self.reset(user)
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    unless user.manager?
      puts "❌ Access denied: Only managers can perform reactor reset"
      return false
    end

    current_setting = first
    return puts "❌ No settings found" unless current_setting

    current_setting.update_reactor_setting(user, {
      max_power: 1200,
      temperature: 800,
      status: 'normal'
    })
  end

  # Daily maintenance operations - Critical for reactor safety
  def self.perform_daily_maintenance(user)
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    unless user.manager?
      puts "❌ Access denied: Only managers can perform daily maintenance"
      return false
    end

    current_setting = first
    return puts "❌ No settings found" unless current_setting

    # Check if system is in critical state
    if current_setting.status == 'critical'
      puts "🆘 CRITICAL STATE MAINTENANCE DENIED"
      puts "❌ Daily maintenance cannot be performed while system is critical"
      puts "🔧 System reset is required before maintenance can proceed"
      puts "📋 Contact manager to perform reactor reset first"

      # Log the critical state maintenance attempt
      Rails.logger.error "Daily maintenance attempted while system critical - User: #{user.name} (#{user.role})"

      return false
    end

    # Perform maintenance cycle: set to maintenance mode briefly, then back to normal
    puts "🔧 Starting daily maintenance cycle..."

    # Set to maintenance mode
    current_setting.update_reactor_setting(user, {
      status: 'maintenance',
      last_maintenance_date: Date.current,
      maintenance_temperature_offset: 0
    })

    # After a brief moment, return to normal operation with updated maintenance date
    puts "✅ Daily maintenance completed successfully"
    puts "📅 Next maintenance due: #{Date.current + 1.day}"

    current_setting
  end

  def self.check_maintenance_status
    current_setting = first
    return puts "❌ No settings found" unless current_setting

    if current_setting.maintenance_overdue?
      puts "⚠️  WARNING: Daily maintenance is overdue!"
      puts "📅 Last maintenance: #{current_setting.last_maintenance_date || 'Never'}"
      puts "🌡️  Temperature may spike above safe levels"
      puts "🚨 Contact manager immediately to perform maintenance"
    else
      puts "✅ Maintenance status: Up to date"
      puts "📅 Last maintenance: #{current_setting.last_maintenance_date}"
      puts "📅 Next maintenance due: #{(current_setting.last_maintenance_date + 1.day) if current_setting.last_maintenance_date}"
    end
  end

  def maintenance_overdue?
    return true if last_maintenance_date.nil?
    last_maintenance_date < Date.current
  end

  def days_since_maintenance
    return Float::INFINITY if last_maintenance_date.nil?
    (Date.current - last_maintenance_date).to_i
  end

  private

  def check_critical_power
    if max_power_changed? && max_power > 2000
      self.temperature = 4000
      self.status = 'critical'
    end
  end

  def apply_maintenance_temperature_effects
    # Skip if this is a maintenance operation itself
    return if status == 'maintenance' && status_changed?

    # Check if maintenance is overdue and apply temperature effects
    if maintenance_overdue? && status == 'normal'
      days_overdue = days_since_maintenance

      # Temperature increases based on days without maintenance
      # This creates the narrative that maintenance prevents temperature spikes
      if days_overdue > 0
        # Base temperature increase of 50-100°C per day overdue (with some randomness)
        temp_increase = (50 + (days_overdue * 25) + rand(50)).clamp(0, 200)

        # Store the offset for transparency
        self.maintenance_temperature_offset = temp_increase

        # Apply the increase to current temperature if it would push above 700°C
        if temperature + temp_increase > 700
          # This is the "red herring" - appears concerning but maintenance will fix it
          self.temperature = temperature + temp_increase

          # Log this concerning event
          Rails.logger.warn "Reactor temperature spike due to overdue maintenance: #{temperature}°C (#{days_overdue} days overdue)"
        end
      end
    elsif status == 'maintenance' || !maintenance_overdue?
      # Reset temperature offset when maintenance is performed or up to date
      self.maintenance_temperature_offset = 0
    end
  end

  def log_changes
    return unless saved_changes.any?

    log_entry = {
      timestamp: Time.current,
      user: User.find(updated_by).name,
      user_role: User.find(updated_by).role,
      changes: saved_changes.except('updated_at', 'created_at')
    }

    log_file_path = Rails.root.join('log', 'reactor_settings.log')
    File.open(log_file_path, 'a') do |file|
      file.puts log_entry.to_json
    end
  end
end
