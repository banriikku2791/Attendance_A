class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_or_correct_user, only: [:show, :index]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info, :edit_basic_all, :update_basic_all]
  before_action :set_one_month_or_week, only: :show

  def index
    @user_key = ""
    if params[:keyword].nil? 
      @users = User.paginate(page: params[:page])
    else
      @users = User.paginate(page: params[:page]).search(params[:keyword])
      @user_key = params[:keyword]
    end
  end

  def show
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

  private

    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
    end

    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time)
    end

    def bp
      params.require(:user).permit(:basic_time, :work_time)
    end

end