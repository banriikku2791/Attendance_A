class AddBeforeNoteAttendanceChange < ActiveRecord::Migration[5.1]
  def change
    add_column :attendance_changes, :before_note, :string
    add_column :attendance_changes, :before_ck_tomorrow_kintai, :string
  end
end
