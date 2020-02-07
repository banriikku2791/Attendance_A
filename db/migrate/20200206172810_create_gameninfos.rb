class CreateGameninfos < ActiveRecord::Migration[5.1]
  def change
    create_table :gameninfos do |t|
      t.integer :keyid
      t.date :worked_on
      t.string :started_at
      t.string :finished_at
      t.string :ck_tomorrow_kintai
      t.string :note
      t.string :employee_number
      t.string :normal_msg
      t.string :error_msg

      t.timestamps
    end
  end
end
