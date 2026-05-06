class User < ApplicationRecord
  has_secure_password

  ROLES = %w[engineer intern manager].freeze

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  def engineer?
    role == 'engineer'
  end

  def intern?
    role == 'intern'
  end

  def manager?
    role == 'manager'
  end

  # Console helper methods
  def self.find_by_name(name)
    find_by("LOWER(name) = ?", name.downcase)
  end

  def self.engineers
    where(role: 'engineer')
  end

  def self.interns
    where(role: 'intern')
  end

  def self.managers
    where(role: 'manager')
  end

  def create_setting(attributes = {})
    Setting.create_reactor_setting(self, attributes)
  end

  def update_current_setting(attributes = {})
    current_setting = Setting.first
    return puts "❌ No settings found" unless current_setting

    current_setting.update_reactor_setting(self, attributes)
  end

  def delete_current_setting
    current_setting = Setting.first
    return puts "❌ No settings found" unless current_setting

    current_setting.delete_reactor_setting(self)
  end

  def reset_reactor
    Setting.reset(self)
  end

  def perform_daily_maintenance
    Setting.perform_daily_maintenance(self)
  end
end
