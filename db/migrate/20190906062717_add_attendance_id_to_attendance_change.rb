class AddAttendanceIdToAttendanceChange < ActiveRecord::Migration[5.1]
  def change
    add_reference :attendance_changes, :attendance, foreign_key: true
  end
end
