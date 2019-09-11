class AttendanceChange < ApplicationRecord
  belongs_to :user
  belongs_to :attendance

  attr_accessor :ck_change
end
