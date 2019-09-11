class ChangeDataDesignatedWorkStartTimeToUser < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :designated_work_start_time, :string, default: '0800'
  end
end
