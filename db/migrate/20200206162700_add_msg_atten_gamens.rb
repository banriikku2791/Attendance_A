class AddMsgAttenGamens < ActiveRecord::Migration[5.1]
  def change
    add_column :atten_gamen, :normal_msg, :string
    add_column :atten_gamen, :error_msg, :string
  end
end
