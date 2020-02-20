class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  $days_of_the_week = %w{日 月 火 水 木 金 土}

  # beforフィルター

  # paramsハッシュからユーザーを取得します。
  def set_user
    @user = User.find(params[:id])
  end

  # paramsハッシュからユーザーを取得します。
  def set_user2
    @user = User.find(params[:user_id])
  end

  # paramsハッシュから拠点情報を取得
  def set_base
    @base = Base.find(params[:id])
  end

  # ログイン済みのユーザーか確認します。
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end

  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  def correct_user
    # puts "-----------------correct_user------------------"
    # puts current_user?(@user)
    unless current_user?(@user)
      flash[:danger] = "参照および編集権限がありません。（ログインユーザーではない）"
      redirect_to(root_url)
    end
  end

  # システム管理権限所有かどうか判定します。
  def admin_user
    # puts "-----------------admin_user------------------"
    # puts current_user.admin?
    unless current_user.admin?
      flash[:danger] = "参照および編集権限がありません。（管理者権限なし）"
      redirect_to(root_url)
    end
  end

  # システム管理権限所有者でないことを判定します。
  def un_admin_user
    # puts "-----------------un_admin_user------------------"
    # puts current_user.admin?
    if current_user.admin?
      flash[:danger] = "参照および編集権限がありません。（管理者権限あり）"
      redirect_to(root_url)
    end
  end

  # 管理権限者、または現在ログインしているユーザーを許可します。
  def admin_or_correct_user
    # puts "-----------------admin_or_correct_user------------------"
    # puts current_user?(@user)
    # puts current_user.admin?
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "参照および編集権限がありません。"
      redirect_to(root_url)
    end  
  end

  # 日付と時間の結合
  def dchange(time)
    require 'date'
    d = Date.today
    return DateTime.parse(d.strftime("%Y/%m/%d") + " " + time + ":00") - Rational(9,24)
  end

  # ページ出力前に1ヶ月分または１週間分のデータ存在確認と存在しないデータは作成しセットします。
  def set_one_month_or_week
    if params[:chenge_mw] == "w" # 週指定の場合
      @first_day = params[:date].nil? ?
      Date.current.beginning_of_week : params[:date].to_date
      @last_day = @first_day.end_of_week
      @first_day_m = params[:date].nil? ?
      Date.current.beginning_of_month : params[:date].to_date.beginning_of_month
      @last_day_m = @first_day_m.end_of_month
      @select_area = "w"
    else # 月指定の場合
      @first_day = params[:date].nil? ?
      Date.current.beginning_of_month : params[:date].to_date.beginning_of_month
      @last_day = @first_day.end_of_month
      @first_day_m = @first_day
      @last_day_m = @last_day
      @select_area = "m"
    end
    
    # 勤怠変更申請中の有無
    @cnt_change = AttendanceChange.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1").count
    @info_change = AttendanceChange.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1")
    # 残業申請中の有無
    @cnt_end = AttendanceEnd.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1").count
    @info_end = AttendanceEnd.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1")
    # 締め処理有無
    @cnt_fix = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m, request: "1").count

    @name_fix = ""
    @req_fix = ""
    name_num = 0
    if @cnt_fix == 1
      attendanceFix_r = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:request).limit(1).order('created_at DESC')
      attendanceFix_r.each do |ar|
        @req_fix = ar.request
      end
      # puts "@req_fix:" + @req_fix
      attendanceFix_num = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:superior_employee_number).limit(1).order('created_at DESC')
      attendanceFix_num.each do |anum|
        name_num = anum.superior_employee_number
      end
      # puts "name_num:" + name_num.to_s 
      user_name = User.where(employee_number: name_num).select(:name).limit(1) 
      user_name.each do |un|
        @name_fix = un.name
      end
    else
      attendanceFix_r = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:request).limit(1).order('created_at DESC')
      attendanceFix_r.each do |ar|
        @req_fix = ar.request
      end
      attendanceFix_num = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:superior_employee_number).limit(1).order('created_at DESC')
      attendanceFix_num.each do |anum|
        name_num = anum.superior_employee_number
      end
      # puts "name_num:" + name_num.to_s 
      user_name = User.where(employee_number: name_num).select(:name).limit(1) 
      user_name.each do |un|
        @name_fix = un.name
      end
    end
    
    # 編集当日の該当月
    @default_day = Date.current
    one_month_or_week = [*@first_day..@last_day] # 対象の月の日数を代入します。
    
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得します。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @attendances_m = @user.attendances.where(worked_on: @first_day_m..@last_day_m).order(:worked_on)
    
    unless one_month_or_week.count == @attendances.count # それぞれの件数（日数）が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
          one_month_or_week.each { |day| 
            attendances2 = @user.attendances.where(worked_on: day)
            if attendances2.count == 0
              @user.attendances.create!(worked_on: day)
            end
          }
      end
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end

  # ページ出力前に1ヶ月分または１週間分のデータ存在確認と存在しないデータは作成しセットします。
  def set_one_month_or_week_2

    if params[:chenge_mw] == "w" # 週指定の場合
      @first_day = params[:date].nil? ?
      Date.current.beginning_of_week : params[:date].to_date
      @last_day = @first_day.end_of_week
      @first_day_m = params[:date].nil? ?
      Date.current.beginning_of_month : params[:date].to_date.beginning_of_month
      @last_day_m = @first_day_m.end_of_month
      @select_area = "w"
    else # 月指定の場合
      @first_day = params[:date].nil? ?
      Date.current.beginning_of_month : params[:date].to_date.beginning_of_month
      @last_day = @first_day.end_of_month
      @first_day_m = @first_day
      @last_day_m = @last_day
      @select_area = "m"
    end

    # 締め処理有無
    @name_fix = ""
    @req_fix = ""
    name_num = 0
    
    # 申請有無
    @cnt_fix = AttendanceFix.where(user_id: params[:user_id], worked_on: @first_day_m, request: "1").count
    
    # 承認状況取得
    attendanceFix_r = AttendanceFix.where(user_id: params[:user_id], worked_on: @first_day_m).select(:request).limit(1).order('created_at DESC')
    attendanceFix_r.each do |ar|
      @req_fix = ar.request
    end
    
    # 上長名取得
    attendanceFix_num = AttendanceFix.where(user_id: params[:user_id], worked_on: @first_day_m).select(:superior_employee_number).limit(1).order('created_at DESC')
    attendanceFix_num.each do |anum|
      name_num = anum.superior_employee_number
    end
    user_name = User.where(employee_number: name_num).select(:name).limit(1) 
    user_name.each do |un|
      @name_fix = un.name
    end

    @user = User.find(params[:user_id])
    
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date.beginning_of_month
    @last_day = @first_day.end_of_month
    @first_day_m = @first_day
    @last_day_m = @last_day
    @select_area = "m"

    # 編集当日の該当月
    @default_day = Date.current
    one_month_or_week = [*@first_day..@last_day] # 対象の月の日数を代入します。
    
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得します。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @attendances_m = @user.attendances.where(worked_on: @first_day_m..@last_day_m).order(:worked_on)
    unless one_month_or_week.count == @attendances.count # それぞれの件数（日数）が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
          one_month_or_week.each { |day| 
            attendances2 = @user.attendances.where(worked_on: day)
            if attendances2.count == 0
              @user.attendances.create!(worked_on: day)
            end
          }
      end
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end

  def time_select
    # 時（0～23）
    @t_h = {}
    24.times do |u|
      @t_h[format('%02d', u)] = format('%02d', u)
    end
    # 分（0～59）
    @t_m = {}
    60.times do |u|
      @t_m[format('%02d', u)] = format('%02d', u)
    end
  end
  
  def gamen_ini
    # 画面情報初期化
    Gameninfo.destroy_all
  end

  def date_change(w_day, t_day, ck_sf, ck_to)
    if t_day.present?
      str_d = w_day.year.to_s + format('%02d', w_day.month) + format('%02d', w_day.day) + t_day.slice(0..1) + t_day.slice(3..4) + "00" 
      if ck_sf == "f" && ck_to == "1"
        return Time.zone.parse(str_d) + 86400
      else
        return Time.zone.parse(str_d)
      end
    else
      return nil
    end
  end

  def date_change2(w_day, t_day, ck_sf, ck_to, flg)
    if t_day.present?
      if flg
        str_d = w_day.year.to_s + format('%02d', w_day.month) + format('%02d', w_day.day) + t_day.slice(0..1) + t_day.slice(3..4) + "00" 
      else
        str_d = w_day.year.to_s + format('%02d', w_day.month) + format('%02d', w_day.day) + t_day + "00" 
      end
      if ck_sf == "f" && ck_to == "1"
        return Time.zone.parse(str_d) + 86400
      else
        return Time.zone.parse(str_d)
      end
    else
      return nil
    end
  end

  # attendances_helperにもあるのを補正 exportで使用 controller側でコールできないため
  def working_times_at(start, finish)
    unless start.nil? || finish.nil?
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
    else
      return nil
    end
  end
  
  def set_times_at(targetDay)
    setday = targetDay.nil? ?
    targetDay : I18n.l(targetDay, format: :time_h) + ":" + working_minutes_at(targetDay)
    return setday
  end

  # 以下、attendances_helperにもあるのを補正 exportで使用 controller側でコールできないため
  def working_minutes_at(target_min)
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
  
  # 15分刻みの時間に変換(出社時間用)
  def working_time_rule_s(target_s)
      w_hour = target_s.hour
      w_min = target_s.min
      w_flg = false
      if w_min > 0 && w_min <= 15
        w_min = 15
      elsif w_min > 15 && w_min <= 30
        w_min = 30
      elsif w_min > 30 && w_min <= 45
        w_min = 45
      elsif w_min > 45 && w_min <= 60
        w_min = 0
        if w_hour == 23
          w_hour = 0
          w_flg = true
        else
          w_hour += 1
        end
      end
      s_str = target_s.year.to_s + format('%02d', target_s.month) + format('%02d', target_s.day) +
              format('%02d', w_hour) + format('%02d', w_min) + "00"
      s_time = Time.zone.parse(s_str)
      if w_flg
        s_time += 86400
      end
      return s_time
  end
  
  # 15分刻みの時間に変換(帰社時間用)
  def working_time_rule_f(target_s, target_f, base_at, zan_at, ck_tomorrow_flg, zflg)
      wk_s = nil
      wk_f = nil
      if zflg
        dt = base_at
        dt += 1 if ck_tomorrow_flg == "1"
        dt_str = dt.year.to_s + format('%02d', dt.month) + format('%02d', dt.day) + zan_at + "00"
        wk_f = Time.zone.parse(dt_str)
        wk_s = target_f
      else
        wk_s = working_time_rule_s(target_s)
        wk_f = target_f
      end
      if wk_s > wk_f
        return working_time_rule_s(wk_f)
      else
        w_hour = wk_f.hour
        w_min = wk_f.min
        if w_min >= 0 && w_min < 15
          w_min = 0
        elsif w_min >= 15 && w_min < 30
          w_min = 15
        elsif w_min >= 30 && w_min < 45
          w_min = 30
        elsif w_min >= 45 && w_min < 60
          w_min = 45
        end
        f_str = wk_f.year.to_s + format('%02d', wk_f.month) + format('%02d', wk_f.day) +
                format('%02d', w_hour) + format('%02d', w_min) + "00"
        f_time = Time.zone.parse(f_str)
        return f_time
      end
  end

  # 出社時間(15分刻み形式で返却) 手入力(input_flg = true)
  def working_start(base_at, target_s, input_flg)
    # puts "working_start"
    # puts base_at
    # puts target_s
    tmp_time = nil 
    if input_flg
      str_time = base_at.year.to_s + format('%02d', base_at.month) + format('%02d', base_at.day) + target_s.slice(0..1) + target_s.slice(3..4) + "00"
      tmp_time = Time.zone.parse(str_time)
    else
      tmp_time = target_s
    end
    wk_at = working_time_rule_s(tmp_time)
    puts wk_at
    return wk_at
  end

  # 退社時間(15分刻み形式で返却) 手入力(input_flg = true)
  def working_finish(base_at, target_s, target_f, ck_to, input_flg)
    # puts "working_finish"
    # puts base_at
    # puts target_s
    # puts target_f
    # puts ck_to
    tmp_time_s = nil 
    tmp_time_f = nil
    if input_flg
      str_time_s = base_at.year.to_s + format('%02d', base_at.month) + format('%02d', base_at.day) + target_s.slice(0..1) + target_s.slice(3..4) + "00"
      tmp_time_s = Time.zone.parse(str_time_s)
      str_time_f = base_at.year.to_s + format('%02d', base_at.month) + format('%02d', base_at.day) + target_f.slice(0..1) + target_f.slice(3..4) + "00"
      tmp_time_f = nil
      if ck_to == "1"
        tmp_time_f = Time.zone.parse(str_time_f) + 86400
      else
        tmp_time_f = Time.zone.parse(str_time_f)
      end
    else
      tmp_time_s = target_s
      tmp_time_f = target_f
    end
    wk_at = working_time_rule_f(tmp_time_s, tmp_time_f, nil, nil, nil, false)
    puts wk_at
    return wk_at
  end

  # 終了予定時間(15分刻み形式で返却)
  def working_yotei(base_at, zan_at, ck_tomorrow_flg, target_s, target_f, ck_to)
    # puts "working_yotei"
    # puts base_at
    # puts zan_at
    # puts ck_tomorrow_flg
    # puts target_s
    # puts target_f
    # puts ck_to
    tmp_time_f = working_finish(base_at, target_s, target_f, ck_to)
    wk_at = working_time_rule_f(nil, tmp_time_f, base_at, zan_at, ck_tomorrow_flg, true)
    puts wk_at
    return wk_at
  end
  
end