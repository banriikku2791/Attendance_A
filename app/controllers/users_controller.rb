class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all, :update_all]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all, :update_all]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_or_correct_user, only: [:show, :index]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all]
  before_action :set_one_month_or_week, only: [:show]
  before_action :set_one_month_or_week_2, only: [:show_readonly]

  def index
    if params[:key] == "1"
      @users = User.paginate(page: params[:page])
    elsif params[:key] == "2"
    #  user_kinmu = Attendance.joins(:users)
    #                        .where.not(started_at: nil)
    #                         .select("users.id AS user_id, users.name AS user_name, users.employee_number AS user_number")
    #user_kinmu = Users.all
      user_kinmu = User.where(id: Attendance.where.not(started_at: nil).where(worked_on: Date.current).select(:user_id))
      @users = user_kinmu.paginate(page: params[:page])
      @users_cnt = User.where(id: Attendance.where.not(started_at: nil).where(worked_on: Date.current).select(:user_id)).count
      # puts @users_cnt
    end
  end

  def show
    # 選択月の中で、出社時間が未登録の件数を取得
    @worked_sum = @attendances_m.where.not(started_at: nil).count

    # 上長に依頼されている各種申請件数(1:所属長承認申請,2:勤怠変更申請,3:残業申請)
    @info_cnt_0 = {}
    @info_cnt_1 = {}
    @info_cnt_3 = {}
    (1..3).each do |n|
      val0 = 0 # 上長として本人に　承認依頼がきた件数のワーク変数
      val1 = 0 # 本人から上長へ　　申請中件数のワーク変数　未承認:1(申請中)
      val3 = 0 # 本人から上長へ　　否認件数のワーク変数　　否認　:3(否認)　承認済:2
      if n == 1
        # 所属長承認申請状況
        val0 = AttendanceFix.where(superior_employee_number: @user.employee_number, request: "1").count
        val1 = AttendanceFix.where(user_id: @user.id, request: "1").count    
        val3 = AttendanceFix.where(user_id: @user.id, request: "3").count
      elsif n == 2
        # 勤怠変更申請状況 
        val0 = AttendanceChange.where(superior_employee_number: @user.employee_number, request: "1").count
        val1 = AttendanceChange.where(user_id: @user.id, request: "1").count
        val3 = AttendanceChange.where(user_id: @user.id, request: "3").count
      elsif n == 3
        # 残業申請状況
        val0 = AttendanceEnd.where(superior_employee_number: @user.employee_number, request: "1").count
        val1 = AttendanceEnd.where(user_id: @user.id, request: "1").count
        val3 = AttendanceEnd.where(user_id: @user.id, request: "3").count
      end
      @info_cnt_0[n] = val0
      @info_cnt_1[n] = val1
      @info_cnt_3[n] = val3
    end

    # 上長選択用編集処理(アクセスユーザー本人は除く（上長権限保有していた場合）)
    user_s = User.where(superior: true).where.not(id: @user.id)
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end

  end

  def show_readonly
    @worked_sum = @attendances_m.where.not(started_at: nil).count
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user # 保存成功後、ログインします。
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit      
    end
  end

  def edit_all
  end

  def update_all
    @user = User.find(params[:id])
    if @user.update_attributes(user_params_all)
      flash[:success] = "ユーザー情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_path(key: 1)
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end

  def edit_basic_all
  end

  def update_basic_all
    @user = User.all
    if @user.update_all(basic_time: dchange(bp[:basic_time]), work_time: dchange(bp[:work_time]), updated_at: Time.current.change(sec: 0))
      flash[:success] = "全ユーザーの指定勤務時間および基本勤務時間を更新しました。"
    else
      flash[:danger] = "全ユーザーの指定勤務時間および基本勤務時間の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to edit_basic_all_user_path(current_user)
  end

  def import
    #Object.import(params[:filename])
    #redirect_to "/object"
    registered_count = import_files
    flash[:info] = "#{registered_count}件登録しました"
    redirect_to users_path
    #redirect_to users_path, notice: "#{registered_count}件登録しました"
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :password, :password_confirmation)
    end

    def user_params_all
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, 
        :password_confirmation, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end

    def basic_info_params
      params.require(:user).permit(:affiliation, :basic_time, :work_time)
    end

    def bp
      params.require(:user).permit(:basic_time, :work_time)
    end

    def import_files
      require 'csv'
      # 登録処理前のレコード数
      current_file_row_count = ::User.count
      datas = []
      #debugger
      # windowsで作られたファイルに対応するので、encoding: "SJIS"を付けている
      CSV.foreach(params[:file_data].path, headers: true, encoding: "SJIS") do |row|
        datas << ::User.new({ name: row["name"], email: row["email"], affiliation: row["affiliation"], 
          employee_number: row["employee_number"],
          uid: row["uid"], basic_work_time: row["basic_work_time"],
          designated_work_start_time: row["designated_work_start_time"],
          designated_work_end_time: row["designated_work_end_time"],
          superior: row["superior"], admin: row["admin"], password: row["password"]})
      end
      # importメソッドでバルクインサートできる
      ::User.import(datas)
      # 何レコード登録できたかを返す
      ::User.count - current_file_row_count
    end

end