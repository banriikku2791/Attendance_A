class ChangeBasicWorkTimeToUser < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :basic_work_time, :string, default: '0800'
  end
end
