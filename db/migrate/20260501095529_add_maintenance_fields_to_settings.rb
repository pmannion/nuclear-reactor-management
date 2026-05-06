class AddMaintenanceFieldsToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :last_maintenance_date, :date
    add_column :settings, :maintenance_temperature_offset, :integer
  end
end
