class AddDesignatedWorkToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :designated_work_start_time, :datetime
    add_column :users, :designated_work_end_time, :datetime
  end
end
