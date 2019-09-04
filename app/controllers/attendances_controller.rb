class AttendancesController < ApplicationController

  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :set_user2, only: :update
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_over_work]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month_or_week, only: :edit_one_month

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  def new
  end

  def create
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
        attendance.update_attributes!(item)
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
    # 上長選択用編集処理
    user_s = User.where(superior: true)
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
  end

  def update_over_work
    require 'date'
    attendance = Attendance.find(params[:id])
#    if attendance.update_attributes(note: params[:attendance][:note], end_at: params[:attendance][:end_at])
    if attendance.update_attributes(attendances_params2)
      
      @attendance = Attendance.find(params[:id])
      if params[:attendance][:ck_tommorow] == "1"
        attendance.update_attributes(end_at: @attendance.end_at + 86400)
      end
      @attendance = Attendance.find(params[:id])
      @attendance_end = AttendanceEnd.new(
                          worked_on: @attendance.worked_on,
                          end_at:  @attendance.end_at,
                          reason: @attendance.note,
                          superior_employee_number: params[:employee_number],
                          request: "1",
                          request_at: Time.current,
                          user_id: @attendance.user_id)
      if @attendance_end.save
        flash[:success] = '残業申請完了しました。'
        redirect_to current_user
      else
        flash[:danger] = '残業申請失敗しました。'
        render current_user
      end    
    else
      flash[:danger] = '残業申請失敗しました。'
      render current_user
    end
  end
  
  def edit_end_ck
    #@attendance = Attendance.where(params[:id])
    @attendance_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number).order("worked_on DESC, user_id ASC")
    @user_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number).group(:user_id).order(:user_id)
    @req_sec = { :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
  end

  def update_end_ck
  end
  
  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :reason])[:attendances]
    end

    def attendance_ends_params
      params.require(:attendance_end).permit(:worked_on, :end_at, :reason, :superior_employee_number, :request, :request_at, :confirm_at, :user_id)
    end

    def attendances_params2
      params
        .require(:attendance)
        .permit(Form::Attendance::REGISTRABLE_ATTRIBUTES)
    end

    def attendances_params3
      params
        .require(:attendance)
        .permit(Form::Attendance::REGISTRABLE_ATTRIBUTES_2)
    end  

end