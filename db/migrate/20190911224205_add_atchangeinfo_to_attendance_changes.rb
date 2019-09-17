class AddAtchangeinfoToAttendanceChanges < ActiveRecord::Migration[5.1]
  def change
    add_column :attendance_changes, :deleted_at, :datetime
    add_column :attendance_changes, :deleted_flg, :boolean, default: false
  end
end
