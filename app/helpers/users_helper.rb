module UsersHelper

  # 勤怠基本情報を指定のフォーマットで返します。  
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0)
  end

  def format_basic_info_m(time, day)
    total_m = ((((time.hour * 60) + time.min) * day)) / 60.0
    return format("%.2f", total_m)
  end

end