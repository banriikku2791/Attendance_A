class AddTomorrowFlgToAttendance < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :tomorrow_flg, :boolean, default: false 
  end
end
