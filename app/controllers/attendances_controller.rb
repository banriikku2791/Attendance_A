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
  end

  def show
  end

  def destroy
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
                               request_change: "1"
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
  end

  def update_end_ck
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
  end

  def update_change_ck
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

  def edit_fix_ck
    @user = User.find(params[:id])
    @attendance_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number).group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
  end

  def update_fix_ck
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
      params
        .require(:attendance)
        .permit(Form::Attendance::REGISTRABLE_ATTRIBUTES)
    end

    def attendances_params6
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

  

end