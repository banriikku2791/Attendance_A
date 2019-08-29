class BasesController < ApplicationController
  
  before_action :set_base, only: [:show, :edit, :update, :destroy]

  def new
  end

  def index
    @bases = Base.paginate(page: params[:page])
  end

  def edit
  end

  def create
  end
  
  def destroy
  end

end
