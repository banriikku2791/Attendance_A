class AddBeforeEndAtAttendanceEnds < ActiveRecord::Migration[5.1]
  def change
    add_column :attendance_ends, :before_end_at, :string
    add_column :attendance_ends, :ck_tomorrow_before, :string
  end
end
