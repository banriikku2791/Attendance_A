class CreateAttendanceChanges < ActiveRecord::Migration[5.1]
  def change
    create_table :attendance_changes do |t|
      t.date :worked_on
      t.string :note
      t.datetime :after_started_at
      t.datetime :after_finished_at
      t.datetime :before_started_at
      t.datetime :before_finished_at
      t.integer :superior_employee_number
      t.string :request
      t.datetime :request_at
      t.datetime :confirm_at
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
