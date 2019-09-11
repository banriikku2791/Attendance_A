module UsersHelper

  # 勤怠基本情報を指定のフォーマットで返します。  
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0)
  end

  def format_basic_info_m(time, day)
    total_m = ((((time.hour * 60) + time.min) * day)) / 60.0
    return format("%.2f", total_m)
  end

  def ck_fix_hantei
    puts "ck----------------------------hantei"
    puts @cnt_fix
    puts @req_fix
    puts @name_fix
    
    if @cnt_fix != 0 && @req_fix == "1"
      return @name_fix + "へ申請中"
    elsif @cnt_fix != 0 && @req_fix == "2"
      return "承認済"
    elsif @cnt_fix != 0 && @req_fix == "3"
      return "否認"
    else
      return "未"
    end
  end

end