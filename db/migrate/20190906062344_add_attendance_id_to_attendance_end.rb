class AddAttendanceIdToAttendanceEnd < ActiveRecord::Migration[5.1]
  def change
    add_reference :attendance_ends, :attendance, foreign_key: true
  end
end
