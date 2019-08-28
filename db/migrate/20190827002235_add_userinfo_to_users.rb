class AddUserinfoToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :basic_work_time, :datetime, default: Time.current.change(hour: 8, min: 0, sec: 0)
    add_column :users, :employee_number, :integer
    add_column :users, :uid, :string
  end
end
