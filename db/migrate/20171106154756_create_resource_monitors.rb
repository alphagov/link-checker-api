class CreateResourceMonitors < ActiveRecord::Migration[5.0]
  def change
    create_table :resource_monitors do |t|
      t.boolean :enabled, default: true
      t.string :service

      t.timestamps
    end
  end
end
