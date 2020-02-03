class BasesController < ApplicationController
  
  before_action :set_base, only: [:show, :edit, :update, :destroy]
  before_action :admin_user, only: [:create_base_info, :create, :index, :edit, :update, :destroy]

  def new
    @base = Base.new
  end

  def create_base_info
    @base = Base.new(base_params)
    if @base.save
      flash[:success] = '拠点情報を登録しました'
      redirect_to @base
    else
      render :new
    end
  end

  def create
    @base = Base.new(base_params)
    if @base.save
      flash[:success] = '拠点情報を登録しました'
      redirect_to bases_path
    else
      render :new
    end
  end

  def index
    @bases = Base.paginate(page: params[:page])
  end

  def edit
  end

  def update
    if @base.update_attributes(base_params)
      flash[:success] = "#{@base.base_name}の拠点情報を更新しました。"
      redirect_to bases_path
    else
      render :edit      
    end
  end

  def destroy
    @base.destroy
    flash[:success] = "#{@base.base_name}のデータを削除しました。"
    redirect_to bases_path

  end

  private

    def base_params
      params.require(:base).permit(:base_number, :base_name, :work_bunrui)
    end

end
