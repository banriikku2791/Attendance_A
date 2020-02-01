class RemoveTomorrowBeforeAttendanceEnds < ActiveRecord::Migration[5.1]
  def change
    remove_column :attendance_ends, :ck_tomorrow_before, :string
  end
end
