class ChangeDataDesignatedWorkEndTimeToUser < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :designated_work_end_time, :string, default: '1700'
  end
end
