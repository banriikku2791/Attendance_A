class AttendanceFix < ApplicationRecord
  belongs_to :user
  
  attr_accessor :ck_change
end
