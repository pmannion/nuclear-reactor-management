require_relative '../services/reset_authorization_service'

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
      setting
    else
      nil
    end
  end

  def update_reactor_setting(user, attributes = {})
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    # Check if engineer is trying to update reactor in critical state
    if status == 'critical' && user.engineer?
      return nil
    end

    self.updated_by = user.id

    if update(attributes)
      self
    else
      nil
    end
  end

  def delete_reactor_setting(user)
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    if destroy
      true
    else
      false
    end
  end

  # Convenience methods for common operations
  def self.emergency_shutdown(user)
    current_setting = first
    return nil unless current_setting

    current_setting.update_reactor_setting(user, {
      status: 'maintenance',
      max_power: 0,
      min_power: 0,
      temperature: 20
    })
  end

  def self.set_normal_operation(user)
    current_setting = first
    return nil unless current_setting

    current_setting.update_reactor_setting(user, {
      status: 'normal',
      max_power: 1800,
      min_power: 200,
      temperature: 650
    })
  end

  def self.reset(user)


    unless user.manager?
      return false
    end

    current_setting = first
    return nil unless current_setting

    # Generate a reactor ID for this reset request (simulating a real reactor identifier)
    reactor_id = current_setting.id || 1001

    # Request authorization from the external API
    auth_result = ResetAuthorizationService.request_reset_code(reactor_id, user)

    unless auth_result[:success]
      puts "Reactor reset failed"
      puts "Contact Nuclear Safety Authority support: 1-800-NUCLEAR"
      puts "🔄 Try again later or check API status"

      # Log the failed authorization attempt
      log_entry = {
        timestamp: Time.current,
        user: user.name,
        user_role: user.role,
        action: "reactor_reset_authorization_failed",
        reason: auth_result[:error],
        reactor_id: reactor_id,
        authorization_code: auth_result[:code] || "none"
      }

      log_file_path = Rails.root.join('log', 'reactor_settings.log')
      File.open(log_file_path, 'a') do |file|
        file.puts log_entry.to_json
      end

      return false
    end

    # If authorization somehow succeeded (which shouldn't happen with our broken API)
    # Log the successful authorization code
    auth_log_entry = {
      timestamp: Time.current,
      user: user.name,
      user_role: user.role,
      action: "reactor_reset_authorization_received",
      reactor_id: reactor_id,
      authorization_code: auth_result[:code]
    }

    log_file_path = Rails.root.join('log', 'reactor_settings.log')
    File.open(log_file_path, 'a') do |file|
      file.puts auth_log_entry.to_json
    end

    # Perform the actual reset
    result = current_setting.update_reactor_setting(user, {
      max_power: 1200,
      temperature: 800,
      status: 'normal'
    })

    if result
      # Log the successful reactor reset with authorization code
      reset_log_entry = {
        timestamp: Time.current,
        user: user.name,
        user_role: user.role,
        action: "reactor_reset_completed",
        reactor_id: reactor_id,
        authorization_code: auth_result[:code],
        new_settings: {
          max_power: 1200,
          temperature: 800,
          status: 'normal'
        }
      }

      log_file_path = Rails.root.join('log', 'reactor_settings.log')
      File.open(log_file_path, 'a') do |file|
        file.puts reset_log_entry.to_json
      end
    end

    result
  end

  # Daily maintenance operations - Critical for reactor safety
  def self.perform_daily_maintenance(user)
    unless user.is_a?(User)
      raise ArgumentError, "First parameter must be a User object"
    end

    unless user.manager?
      return false
    end

    current_setting = first
    return nil unless current_setting

    # Check if system is in critical state
    if current_setting.status == 'critical'
      # Log the critical state maintenance attempt
      Rails.logger.error "Daily maintenance attempted while system critical - User: #{user.name} (#{user.role})"

      return false
    end

    # Set to maintenance mode
    current_setting.update_reactor_setting(user, {
      status: 'maintenance',
      last_maintenance_date: Date.current,
      maintenance_temperature_offset: 0
    })

    current_setting
  end

  def self.check_maintenance_status
    current_setting = first
    return nil unless current_setting

    current_setting.maintenance_overdue?
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
