class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, if_not_exists: true do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
  end
end
