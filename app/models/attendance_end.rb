class AttendanceEnd < ApplicationRecord
  belongs_to :user
  belongs_to :attendance
  #validates :ck_change,  presence: true
  attr_accessor :ck_change
end
