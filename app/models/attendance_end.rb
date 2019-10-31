class AttendanceEnd < ApplicationRecord
  belongs_to :user
  belongs_to :attendance
  #validates :ck_change,  presence: true
  attr_accessor :ck_change

  # 業務処理内容または指示者確認が存在しない場合、登録は無効
  validate :finished_at_is_invalid_without_a_started_at

  def finished_at_is_invalid_without_a_started_at
    errors.add(:reason,"と指示者確認の両方の入力が必要です") if reason.blank? || superior_employee_number.blank?
  end


end
