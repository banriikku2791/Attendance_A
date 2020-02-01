class AddBeforeReasonAttendanceEnds < ActiveRecord::Migration[5.1]
  def change
    add_column :attendance_ends, :before_reason, :string
  end
end
