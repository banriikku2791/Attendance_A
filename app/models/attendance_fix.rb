class AttendanceFix < ApplicationRecord
  belongs_to :user
  
  attr_accessor :ck_change

  # 所属長を指定していない場合、登録は無効
  # validate :register_is_invalid_without_a_superior_employee_number
  # validates :superior_employee_number,  presence: true
  
  # def register_is_invalid_without_a_superior_employee_number
  #   errors.add("所属長の指定が必要です") if superior_employee_number.blank?
  # end

end
