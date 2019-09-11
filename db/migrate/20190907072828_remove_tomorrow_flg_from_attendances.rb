class RemoveTomorrowFlgFromAttendances < ActiveRecord::Migration[5.1]
  def change
    remove_column :attendances, :tomorrow_flg, :boolean
  end
end
