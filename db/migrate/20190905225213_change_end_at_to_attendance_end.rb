class ChangeEndAtToAttendanceEnd < ActiveRecord::Migration[5.1]
  def change
    change_column :attendance_ends, :end_at, :string
  end
end
