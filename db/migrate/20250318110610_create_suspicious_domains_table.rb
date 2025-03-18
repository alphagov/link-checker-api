class CreateSuspiciousDomainsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :suspicious_domains do |t|
      t.string :domain, null: false
      t.timestamps
    end

    add_index :suspicious_domains, :domain, unique: true
  end
end
