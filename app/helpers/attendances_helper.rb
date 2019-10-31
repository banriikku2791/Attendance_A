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

  end

  # 終了予定時間と指定終了勤務時間を受け取り、時間外時間を計算して返します。
  # 第１引数 : 基準となる日付（date型）
  # 第２引数 : 終了予定時間（ex:'1900'）
  # 第３引数 : 退社日時（datetime型）
  # 第４引数 : 翌日フラグ（'0' or '1'） 
  def working_overtimes(targetday, yotei, base, tflg)
    # require "date"
    #dt = Time.current
    dt = targetday
    # str_b = dt.year.to_s + format('%02d', dt.month) + format('%02d', dt.day) + base + "00" 
    # str_b = dt.year.to_s + format('%02d', dt.month) + format('%02d', dt.day) + base.delete(":") + "00"
    str_b = base
    # dt += 86400 if tflg == "1"
    #dt += 86400 if tflg
    dt += 1 if tflg == "1"
    str_y = dt.year.to_s + format('%02d', dt.month) + format('%02d', dt.day) + yotei + "00"
    puts tflg
    puts str_b
    puts str_y
    #start = Time.parse(str_b)
    start = str_b
    #finish = Time.parse(str_y)
    finish = Time.zone.parse(str_y)
    puts start
    puts finish
    w_times_sa = finish - start
    w_times = (((w_times_sa) / 60) / 60.0) - ((w_times_sa) / 60).div(60)

    if w_times >= 0 && w_times < 0.25
      format("%.2f", ((((w_times_sa) / 60).div(60))))
    elsif w_times >= 0.25 && w_times < 0.50
      format("%.2f", ((((w_times_sa) / 60).div(60))) + 0.25)
    elsif w_times >= 0.50 && w_times < 0.75
      format("%.2f", ((((w_times_sa) / 60).div(60))) + 0.5)
    else
      format("%.2f", ((((w_times_sa) / 60).div(60))) + 0.75)
    end 

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

  # 勤怠変更申請中チェック用　指定日が申請中であればTrueを返却する
  def change_check(obj, targetDay)
    flg = false
    obj.each do |day|
      if day.worked_on == targetDay
        flg = true
      end
    end
    return flg
  end

  # 勤怠変更申請中チェック用　指定日が申請中であればTrueを返却する
  # 第１引数 : テーブル情報
  # 第２引数 : チェック対象となる日付
  # 第３引数 : Hash情報
  def change_superior_name(obj, targetDay, names)
    superiorName = "該当なし"
    obj.each do |day|
      if day.worked_on == targetDay
        superiorName = names.key(day.superior_employee_number)
      end
    end
    return superiorName
  end  

end