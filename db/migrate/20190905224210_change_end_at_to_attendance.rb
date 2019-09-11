class ChangeEndAtToAttendance < ActiveRecord::Migration[5.1]
  def change
    change_column :attendances, :end_at, :string
  end
end
