class ChangeDefaultAdminForUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :admin, false
  end
end
