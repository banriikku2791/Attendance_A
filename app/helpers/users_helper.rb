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
  
  def info_cnt_title(kbn,num)
    if kbn == 1
      if num == 1
        return "【所属長承認申請のお知らせ】"
      elsif num == 2
        return "【勤怠変更申請のお知らせ】　"
      elsif num == 3
        return "【残業申請のお知らせ】　　　"
      end
    else
      if num == 1
        return "件の通知があります。"
      elsif num == 2
        return "件が未承認です。"
      elsif num == 3
        return "件の否認があります。"
      elsif num == 4
        return "件の未承認と"
      end
    end
  end

  def zan_info(obj)
    output = ""
    output1 = ""
    output2 = ""
    # 残業申請状況確認
    if obj.request_end == "1"
      employee_num = 0
      employee_name = ""
      atten_num = AttendanceEnd.where(attendance_id: obj.id, request: "1").select(:superior_employee_number)
      atten_num.each do |e_num|
        employee_num = e_num.superior_employee_number 
      end
      if employee_num != 0
        atten_name = User.where(employee_number: employee_num).select(:name)
        atten_name.each do |e_name|
          employee_name = e_name.name
        end
      end
      output1 = employee_name + "へ残業申請中"
    elsif obj.request_end == "2"
      output1 = "残業承認済"
    elsif obj.request_end == "3"
      output1 = "残業否認"
    end
    # 勤怠変更申請状況確認
    if obj.request_change == "1"
      employee_num = 0
      employee_name = ""
      atten_num = AttendanceChange.where(attendance_id: obj.id, request: "1").select(:superior_employee_number)
      atten_num.each do |e_num|
        employee_num = e_num.superior_employee_number 
      end
      if employee_num != 0
        atten_name = User.where(employee_number: employee_num).select(:name)
        atten_name.each do |e_name|
          employee_name = e_name.name
        end
      end
      output2 = employee_name + "へ勤怠変更申請中"
    elsif obj.request_change == "2"
      output2 = "勤怠編集承認済"
    elsif obj.request_change == "3"
      output2 = "勤怠編集否認"
    end
    if output1.present?
      if output2.present?
        output = output1 + "\n" + output2
      else
        output = output1
      end
    elsif output2.present?
      output = output2
    end
    return output    
  end

  def nl2br(str)
    h(str).gsub(/\R/, "<br>")
  end

  def time_change(data)
    puts data
    return "08:00"
  end

end