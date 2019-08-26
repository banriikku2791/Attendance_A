module AttendancesHelper

  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出社' if attendance.started_at.nil?
      return '帰社' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    return false
  end

  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    #debugger
    w_times = (((finish - start) / 60) / 60.0) - ((finish - start) / 60).div(60)
    if w_times >= 0 && w_times < 0.25
      format("%.2f", ((((finish - start) / 60).div(60))))
    elsif w_times >= 0.25 && w_times < 0.50
      format("%.2f", ((((finish - start) / 60).div(60))) + 0.25)
    elsif w_times >= 0.50 && w_times < 0.75
      format("%.2f", ((((finish - start) / 60).div(60))) + 0.5)
    else
      format("%.2f", ((((finish - start) / 60).div(60))) + 0.75)
    end   
    #format("%.2f", (((finish - start) / 60) / 60.0))
  end
  
  def working_minutes(target_min)
    w_min = l(target_min, format: :time_m).to_i
    if w_min >= 0 && w_min < 15
      return "00"
    elsif w_min >= 15 && w_min < 30
      return "15"
    elsif w_min >= 30 && w_min < 45
      return "30"
    else
      return "45"
    end
  end

end