class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.boolean :read, default: false
      t.datetime :created_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :created_at]
  end
end
