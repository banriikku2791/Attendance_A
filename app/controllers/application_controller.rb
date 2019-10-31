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
    redirect_to(root_url) unless current_user?(@user)
  end

  # システム管理権限所有かどうか判定します。
  def admin_user
    redirect_to root_url unless current_user.admin?
  end

  # 管理権限者、または現在ログインしているユーザーを許可します。
  def admin_or_correct_user
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
    puts "Cnt_change"
    puts @cnt_change
    @info_change = AttendanceChange.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1")

    # 残業申請中の有無
    @cnt_end = AttendanceEnd.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1").count
    puts "Cnt_end"
    puts @cnt_end
    @info_end = AttendanceEnd.where(user_id: params[:id], worked_on: @first_day_m..@last_day_m, request: "1")

    # 締め処理有無
    @cnt_fix = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).count
    
#    puts "@cnt_fix:" + @cnt_fix.to_s 
    @name_fix = ""
    @req_fix = ""
    name_num = 0
    if @cnt_fix != 0
      attendanceFix_r = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:request).limit(1).order('created_at DESC')
      attendanceFix_r.each do |ar|
        @req_fix = ar.request
      end
#puts "@req_fix:" + @req_fix
      attendanceFix_num = AttendanceFix.where(user_id: params[:id], worked_on: @first_day_m).select(:superior_employee_number).limit(1).order('created_at DESC')
      attendanceFix_num.each do |anum|
        name_num = anum.superior_employee_number
      end
#puts "name_num:" + name_num.to_s 
      user_name = User.where(employee_number: name_num).select(:name).limit(1) 
      user_name.each do |un|
        @name_fix = un.name
      end
#puts "@name_fix:" + @name_fix 
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

  def date_change(w_day, t_day, ck_sf, ck_to)
    str_d = w_day.year.to_s + format('%02d', w_day.month) + format('%02d', w_day.day) + t_day.slice(0..1) + t_day.slice(3..4) + "00" 
    if ck_sf == "f" && ck_to == "1"
      return Time.zone.parse(str_d) + 86400
    else
      return Time.zone.parse(str_d)
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

  # attendances_helperにもあるのを補正 exportで使用 controller側でコールできないため
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
  
end