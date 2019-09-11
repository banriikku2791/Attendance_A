class RemoveAttendanceIdFromAttendanceFixes < ActiveRecord::Migration[5.1]
  def change
    remove_column :attendance_fixes, :attendance_id, :integer
  end
end
