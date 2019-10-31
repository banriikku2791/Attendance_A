class AddCktomorrowkintaiFromAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :ck_tomorrow_kintai, :string, default: '0'
  end
end
