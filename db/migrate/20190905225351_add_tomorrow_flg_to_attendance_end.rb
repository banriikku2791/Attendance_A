class AddTomorrowFlgToAttendanceEnd < ActiveRecord::Migration[5.1]
  def change
    add_column :attendance_ends, :tomorrow_flg, :boolean, default: false
  end
end
