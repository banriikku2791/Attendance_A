class AddCktomorrowFromAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :ck_tomorrow, :string, default: '0'
  end
end
