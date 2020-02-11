module UsersHelper

  # 勤怠基本情報を指定のフォーマットで返します。  
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0)
  end

  def format_basic_info_m(time, day)
    total_m = ((((time.hour * 60) + time.min) * day)) / 60.0
    return format("%.2f", total_m)
  end
  
  # 文字列の時間を編集する。値がない場合、初期値を返す
  # kbn  1:開始、2:終了
  # time DBの値を受け取る
  # 戻り値 例．9:00、17:00
  def format_worktime(kbn, time)
    set_time = ""
    if time == "" 
      if kbn == 1
        set_time = " 9:00"
      else
        set_time = "17:00"
      end
    else
      if time.slice(0) == "0"
        set_time = " " + time.slice(1,4)
      else
        set_time = time
      end
    end
    return set_time
  end

  def format_basictime(time)
    set_time = ""
    if time == "" 
      set_time = "8.00"
    else
      tmp_h = time.slice(0,2).to_i
      tmp_m = time.slice(3,2).to_i
      tmp_hm = format("%.2f", ((tmp_h * 60) + tmp_m) / 60.0)
      set_time = tmp_hm.to_s
    end
    return set_time
  end

  def ck_fix_hantei
    if @cnt_fix != 0 && @req_fix == "1"
      return @name_fix + "へ申請中"
    elsif @cnt_fix == 0 && @req_fix == "2"
      return @name_fix + "から承認済"
    elsif @cnt_fix == 0 && @req_fix == "3"
      return @name_fix + "から否認"
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

  # 不要
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
      output2 = "<font color='red'>勤怠編集否認</font>"
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

  # 不要
  # １番目、カラー
  # ２番目　メッセージ
  def zan_info_2(obj)
    output = ""
    output1 = ""
    output2 = ""
    @color = "blue"
    color1 = "blue"
    color2 = "blue"

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
      color1 = "green"
    elsif obj.request_end == "2"
      output1 = "残業承認済"
      color1 = "blue"
    elsif obj.request_end == "3"
      output1 = "残業否認"
      color1 = "red"
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
      color2 = "green"
    elsif obj.request_change == "2"
      output2 = "勤怠編集承認済"
      color2 = "blue"
    elsif obj.request_change == "3"
      output2 = "勤怠編集否認"
      color2 = "red"
    end
    if output1.present?
      if output2.present?
        output = output1 + "\n" + output2 
        @color = color1
      else
        output = output1 
        @color = color1
      end
    elsif output2.present?
      output = output2
      @color = color2
    end
    return output    
  end

  # 指示者確認出力内容編集処理
  # 第１引数：申請の種類（1:残業申請、2:勤怠変更申請、左記以外戻り値は初期値）
  # 第２引数：オブジェクト（Attendanceテーブルの１レコード取得分情報）
  # 戻り値　：～申請中、～承認済、～否認といった文字列
  def shiji_info(kbn,obj)
    # 初期値
    output = ""
    wk_output = ""
    @color = ""
    wk_color = ""
    wk_request = ""
    employee_num = 0
    employee_name = ""
    if kbn == 1
      # 残業申請状況確認
      wk_output = "残業"
      wk_request = obj.request_end
      if wk_request == "1" # 申請中の場合、申請相手の上長の名前を取得
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
      end
    elsif kbn == 2
      # 勤怠変更申請状況確認
      wk_output = "勤怠変更"
      wk_request = obj.request_change
      if wk_request == "1" # 申請中の場合、申請相手の上長の名前を取得
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
      end
    end
    # 出力内容の編集
    if wk_request == "1"
      wk_output = employee_name + "へ" + wk_output + "申請中"
      wk_color = "green"
    elsif wk_request == "2"
      wk_output = wk_output + "承認済"
      wk_color = "blue"
    elsif wk_request == "3"
      wk_output = wk_output + "否認"
      wk_color = "red"
    else
      wk_output = ""
    end
    # 出力内容のリターン
    output = wk_output 
    @color = wk_color
    return output    
  end

  def nl2br(str)
    h(str).gsub(/\R/, "<br>")
  end

  def time_change(data)
    return "08:00"
  end

end