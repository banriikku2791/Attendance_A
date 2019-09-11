class AddAttendanceIdToAttendanceFix < ActiveRecord::Migration[5.1]
  def change
    add_reference :attendance_fixes, :attendance, foreign_key: true
  end
end
