class AddMakeinfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :end_at, :datetime
    add_column :attendances, :reason, :string
    add_column :attendances, :request_end, :string
    add_column :attendances, :request_change, :string
  end
end
