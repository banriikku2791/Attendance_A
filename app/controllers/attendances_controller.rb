class AttendancesController < ApplicationController

  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :set_user2, only: [:update, :create]
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_over_work]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month_or_week, only: :edit_one_month
  before_action :time_select, only: [:edit_over_work]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  def new
  end

  def create
    attendance_fixs = AttendanceFix.new(
                                       worked_on: params[:m_day],
                                       superior_employee_number: params[:user][:employee_number],
                                       request: "1",
                                       request_at: Time.current,
                                       user_id: params[:user_id]
                                      )
    if attendance_fixs.save!
      flash[:success] = "所属長承認申請を行いました。"
      redirect_to current_user
    else
      flash[:danger] = "無効な入力データがあった為、所属長承認申請をキャンセルしました。"
      redirect_to current_user
    end
  end

  def edit
  end

  def index

    #@user = User.find(params[:id])
    #@attendances = @user.attendances.where(worked_on: params[:fday]..params[:lday]).order(:worked_on)

    @attendances = Attendance.all    

    respond_to do |format|
      format.html
      format.csv do
        products_csv
        # send_data render_to_string, filename: "attendances.csv", type: :csv
      end
    end


   # @products = Product.all
  #  respond_to do |format|
  #    format.html
  #    format.csv do
  #      send_data render_to_string, filename: "products.csv", type: :csv
  #    end
  #  end
  end

  def show
  end

  def destroy
  end
  
  def export

    #@user = User.find(params[:id])
    #@attendances = Attendance.all
    @attendances = Attendance.where(user_id: params[:id], worked_on: params[:fday]..params[:lday]).order('worked_on')
    @fday_s = params[:fday]
    respond_to do |format|
      format.html
      format.csv do
        products_csv
        # send_data render_to_string, filename: "attendances.csv", type: :csv
      end
    end



    #users = User.all
#    @user = User.find(params[:id])
#    @attendances = @user.attendances.where(worked_on: params[:fday]..params[:lday]).order(:worked_on)
    
#    respond_to do |format|
#      format.html do
          #html用の処理を書く
#      end 
#      format.csv do
          #csv用の処理を書く
#      end
      
      
#=> "2016/05/23 15:08:47"
      
      
#    end
#    t = Time.current
#    send_data render_to_string, filename: tTime.current.strftime("%Y%m%d%H%M%S") + ".csv", type: :csv
#---------------------------
    
#    File.open('backup.csv', 'w') do |f|
#      csv_string = CSV.generate do |csv|
#        csv << User.column_names
#        users = User.where(id: [1..100])
#        users.each do |user|
#          csv << user.attributes.values_at(*User.column_names)
#        end
#      end
#      f.puts csv_string
#    end
  end

  def update
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      
      if @attendance.update_attributes!(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
      #debugger
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
    # 上長選択用編集処理
    user_s = User.where(superior: true)
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        unless params[:user][:attendances][id][:started_at].blank? && params[:user][:attendances][id][:finished_at].blank?
          wk_ck_tomorrow = params[:user][:attendances][id][:ck_tomorrow]
          wk_a_started_at = date_change(attendance.worked_on, params[:user][:attendances][id][:started_at], "s", wk_ck_tomorrow)
          wk_a_finished_at = date_change(attendance.worked_on, params[:user][:attendances][id][:finished_at], "f", wk_ck_tomorrow)
          wk_b_started_at = attendance.started_at
          wk_b_finished_at = attendance.finished_at
          #変更有無確認
          if wk_a_started_at != wk_b_started_at || wk_a_finished_at != wk_b_finished_at
            attendance.update!(started_at: wk_a_started_at,
                               finished_at: wk_a_finished_at,
                               reason: params[:user][:attendances][id][:reason],
                               request_change: "1",
                               ck_tomorrow: wk_ck_tomorrow
                              ) 
            attendance_change = AttendanceChange.new(
                        worked_on: attendance.worked_on,
                        note: attendance.reason,
                        after_started_at: wk_a_started_at,
                        after_finished_at: wk_a_finished_at,
                        before_started_at: wk_b_started_at,
                        before_finished_at: wk_b_finished_at,
                        superior_employee_number: params[:user][:attendances][id][:employee_number],
                        request: "1",
                        request_at: Time.current,
                        user_id: attendance.user_id,
                        attendance_id: attendance.id)
            attendance_change.save!
          end
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date], chenge_mw: params[:chenge_mw])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date], chenge_mw: params[:chenge_mw])
  end

  def edit_over_work
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    @attendance = Attendance.find(params[:id])
    #@attendance = Attendance.where(id: params[:id])
    #@attendance = Attendance.where(id: params[:id], request_end: "1")
    # 上長選択用編集処理
    user_s = User.where(superior: true)
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
    #debugger
  end

  def update_over_work
    #require 'date'
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendance = Attendance.find(params[:id])
      wk_ck_t = params[:attendance][:ck_tomorrow]
      attendance.update!(note: params[:attendance][:note], 
                                      end_at: params[:end_at_h] + params[:end_at_m],
                                      ck_tomorrow: wk_ck_t,
                                      request_end: "1")
      tflg = false
      tflg = true if wk_ck_t == "1"
      @attendance = Attendance.find(params[:id])
      @attendance_end = AttendanceEnd.new(worked_on: @attendance.worked_on,
                                          end_at:  @attendance.end_at,
                                          reason: @attendance.note,
                                          tomorrow_flg: tflg,
                                          superior_employee_number: params[:employee_number],
                                          request: "1",
                                          request_at: Time.current,
                                          user_id: @attendance.user_id,
                                          attendance_id: @attendance.id
                                          )
      @attendance_end.save!
    end
    flash[:success] = '残業申請完了しました。'
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to current_user
  end
  
  def edit_end_ck
    @user = User.find(params[:id])
    @attendance_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number).group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_end_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]

    ActiveRecord::Base.transaction do # トランザクションを開始します。
    
      attendances_params2.each do |id|
        
        if params[:user][:attendance_ends][id][:ck_change] == "1"
          attendance_end = AttendanceEnd.find(id)
          attendance_end.update_attributes!(request: params[:user][:attendance_ends][id][:request],
                                        confirm_at: Time.current)
          attendance = Attendance.find(attendance_end.attendance_id)
          attendance.update_attributes!(request_end: params[:user][:attendance_ends][id][:request])
        end
      end
    end
    flash[:success] = "残業申請を更新しました。"
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to current_user
  end

  def edit_change_ck
    @user = User.find(params[:id])
    @attendance_change = AttendanceChange.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_change = AttendanceChange.where(superior_employee_number: current_user.employee_number).group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_change_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params3.each do |id|
        if params[:user][:attendance_changes][id][:ck_change] == "1"
          attendance_change = AttendanceChange.find(id)
          attendance_change.update_attributes!(request: params[:user][:attendance_changes][id][:request],
                                        confirm_at: Time.current)
          attendance = Attendance.find(attendance_change.attendance_id)
          attendance.update_attributes!(request_change: params[:user][:attendance_changes][id][:request])
        end
      end
    end
    flash[:success] = "勤怠変更申請を更新しました。"
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to current_user
  end
  
  # 勤怠ログ取得用Ajax処理
  def get_change_month
    render partial: 'select_month_change', locals: {id: params[:id]}
  end

  def edit_change_log
    @user = User.find(params[:id])
    @first_day = params[:select_day]
    @select_area = params[:chenge_mw]
    
    # 一覧表示用-----------------------------------------------------------------------------------------100
    # 勤怠変更承認済みデータを取得
    @attendance_change = AttendanceChange.where(deleted_flg: false, request: "2", user_id: params[:id])
                                         .order("worked_on ASC, request_at ASC")
    # 勤怠変更承認済みデータ件数を取得
    @attendance_change_cnt = AttendanceChange.where(deleted_flg: false, request: "2", user_id: params[:id]).count
    puts @attendance_change_cnt                    
    
    # 年月プルダウン項目制御用---------------------------------------------------------------------------100
    # 勤怠変更承認済みデータを日付の昇順でソート
    atten_ymd = AttendanceChange.where(deleted_flg: false, request: "2", user_id: params[:id]).group(:worked_on).order(:worked_on)
    
    @log_y = {}
    cnt_y = 0
    @log_m = {}
    w_y_a = "0"
    w_y_b = "0"
    w_ym_a = "0"
    w_ym_b = "0"
    w_y_hyouji = ""
    w_y_genzai = "0"

    @w_cnt_y = ""
    @w_cnt_m = ""

    # 年月プルダウンのデフォルト値
    # 親画面から遷移で、親画面で遷移時に選択していた表示年を設定
    if params[:gamen] == "s"
      w_y_hyouji = params[:select_day].slice(0..3)
    end
    
    # 年の編集
    atten_ymd.each do |ymd|
      w_y_a = ymd.worked_on.year.to_s

      w_y_genzai = w_y_a if cnt_y == 0 # 最古の年を初期値に設定、履歴が現在日に該当する年がない場合を最古の年を画面表示のデフォルト値として設定するため
      cnt_y += 1
      if w_y_a != w_y_b
        @log_y[w_y_a] = w_y_a
#        tmpy = params[:select_day]
        puts "year-------------------------------------------"
        puts w_y_a

        if w_y_hyouji == ""
          if w_y_hyouji == w_y_a # デフォルト値の決定
            @w_cnt_y = w_y_a
            w_y_genzai = w_y_a
            puts "year2-------------------------------------------"
            puts @w_cnt_y
          end
        end
      end
      w_y_b = w_y_a
    end
    
    # 月の編集
    atten_ymd.each do |ymd|
      w_y_a = ymd.worked_on.year.to_s
      if w_y_genzai == w_y_a

        w_ym_a = ymd.worked_on.year.to_s + format('%02d', ymd.worked_on.month)

        if w_ym_a != w_ym_b
          @log_m[w_ym_a.slice(4..6)] = w_ym_a
          tmpm = params[:select_day]
          puts "month-------------------------------------------"
          puts tmpm.slice(5..6)
          puts w_ym_a.slice(4..5)
          if tmpm.slice(5..6) == w_ym_a.slice(4..5) # デフォルト値の決定
            @w_cnt_m = w_ym_a
            puts "month2-------------------------------------------"
            puts @w_cnt_m
          end
        end
      end
      w_ym_b = w_ym_a
    end

  end

  def update_change_log
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    puts "Start update_change_log"
    str_target_day = params[:user][:sec_month] + "01"
    from_target_day = str_target_day.to_date.beginning_of_month
    to_target_day = from_target_day.end_of_month
    #ActiveRecord::Base.transaction do # トランザクションを開始します。
      #attendances_params5.each do |id|
      
    attendance_change = AttendanceChange.all
    if attendance_change.where(user_id: params[:id],
                              worked_on: from_target_day..to_target_day,
                              request: "2",
                              deleted_flg: false
                             )
                       .update_all(deleted_at: Time.current,
                                    deleted_flg: true
                                   )

    #if attendance_change.update_all!(deleted_at: Time.current,
    #                                 deleted_flg: true
    #                                )
      #end
    #end
      flash[:success] = params[:user][:sec_year] + "年" + params[:user][:sec_month].slice(4..5) + "月分の勤怠ログをリセットしました。"
      redirect_to attendances_edit_change_log_user_path(current_user, gamen: "r")
    else
  #rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
      flash[:danger] = "無効な入力データがあった為、リセットをキャンセルしました。"
      redirect_to attendances_edit_change_log_user_path(current_user, gamen: "r")
    end
  end

  def edit_fix_ck
    @user = User.find(params[:id])
    @attendance_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number).group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_fix_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params4.each do |id|
        if params[:user][:attendance_fixs][id][:ck_change] == "1"
          attendance_fix = AttendanceFix.find(id)
          attendance_fix.update_attributes!(request: params[:user][:attendance_fixs][id][:request],
                                            confirm_at: Time.current)
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠申請を更新しました。"
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to current_user
  end

  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :ck_tomorrow, :reason, :employee_number])[:attendances]
    end

    def attendances_params2
      params.require(:user).permit(attendance_ends: [:request, :ck_change])[:attendance_ends]
    end

    def attendances_params3
      params.require(:user).permit(attendance_changes: [:request, :ck_change])[:attendance_changes]
    end

    def attendances_params4
      params.require(:user).permit(attendance_fixs: [:request, :ck_change])[:attendance_fixs]
    end

    def attendances_params5
      params.require(:user).permit(attendance_changes: [:deleted_at, :deleted_flg])[:attendance_changes]
    end
    
    def attendances_params9
      params
        .require(:attendance)
        .permit(Form::Attendance::REGISTRABLE_ATTRIBUTES)
    end

    def attendances_params10
      params
        .require(:attendance)
        .permit(Form::Attendance::REGISTRABLE_ATTRIBUTES_2)
    end

    def attendance_ends_params
      params.require(:attendance_end).permit(:worked_on, :end_at, :reason, :superior_employee_number, :request, :request_at, :confirm_at, :user_id)
    end

    def attendance_ends_params2
      params.require(:attendance_end).permit(:request, :confirm_at)
    end

    def products_csv
      require 'csv'
      csv_date = CSV.generate(encoding:Encoding::SJIS) do |csv|
        column_names = %w(日付 曜日 実績出社時間 実績出退社時間 在社時間 備考)
        csv << column_names
        @attendances.each do |attendance|
          column_values = [
            attendance.worked_on,
            $days_of_the_week[attendance.worked_on.wday],
            set_times_at(attendance.started_at),
            set_times_at(attendance.finished_at),
            working_times_at(attendance.started_at, attendance.finished_at),
            attendance.note
          ]
          csv << column_values
        end
      end
#Time.current.strftime("%Y%m%d%H%M%S")
      #send_data(csv_date,filename: "attendances.csv")
      if @fday_s.kind_of?(Date)
        puts "------------------Date"
      elsif @fday_s.kind_of?(Time)
        puts "------------------Time"
      elsif @fday_s.kind_of?(DateTime)
        puts "------------------DateTime"
      elsif @fday_s.kind_of?(String)
        puts "------------------String"
      end
      
      send_data(csv_date,filename: @fday_s.slice(0..6) + "_attendances_" + Time.current.strftime("%Y%m%d%H%M%S") + ".csv")
    end

    # common helper?


end