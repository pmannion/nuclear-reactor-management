class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.integer :max_power
      t.integer :min_power
      t.integer :temperature
      t.string :status
      t.integer :updated_by

      t.timestamps
    end
  end
end
