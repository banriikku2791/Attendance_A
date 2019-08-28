class CreateAttendanceEnds < ActiveRecord::Migration[5.1]
  def change
    create_table :attendance_ends do |t|
      t.date :worked_on
      t.datetime :end_at
      t.string :reason
      t.integer :superior_employee_number
      t.string :request
      t.datetime :request_at
      t.datetime :confirm_at
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
