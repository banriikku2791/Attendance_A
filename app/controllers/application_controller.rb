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

end