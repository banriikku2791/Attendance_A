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
  
  def export
    @attendances = Attendance.where(user_id: params[:id], worked_on: params[:fday]..params[:lday]).order('worked_on')
    @fday_s = params[:fday]
    respond_to do |format|
      format.html
      format.csv do
        products_csv
      end
    end
  end

  def update
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      
      if @attendance.update_attributes!(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
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
    # 上長選択用編集処理(アクセスユーザー本人は除く（上長権限保有していた場合）)
    user_s = User.where(superior: true).where.not(id: params[:id])
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
  end

  def update_one_month
    #件数のカウント
    tmp_cnt = 0
    tmp_cnt_2 = 0
    error_flg = false
    # tmp_cnt = @user.attendances.where(worked_on: params[:f_day]..params[:l_day]).count
    # puts "tmp_cnt_1:" + tmp_cnt.to_s

    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        # 出社時間かつ退社時間の入力必須チェック
        if params[:user][:attendances][id][:started_at].present? && params[:user][:attendances][id][:finished_at].present?
          # 備考かつ指示者確認の入力必須チェック
          if params[:user][:attendances][id][:note].present? && params[:user][:attendances][id][:employee_number].present?
            wk_ck_tomorrow = params[:user][:attendances][id][:ck_tomorrow_kintai]
            wk_a_started_at = date_change(attendance.worked_on, params[:user][:attendances][id][:started_at], "s", wk_ck_tomorrow)
            wk_a_finished_at = date_change(attendance.worked_on, params[:user][:attendances][id][:finished_at], "f", wk_ck_tomorrow)
            wk_b_started_at = attendance.started_at
            wk_b_finished_at = attendance.finished_at
            # 変更有無確認チェック
            if wk_a_started_at != wk_b_started_at || wk_a_finished_at != wk_b_finished_at
              
              ## 入力した出社時間が前日の退社時間より過去となっていないか
              ## および、入力した出社時間が前日の終了予定時間（残業申請中でもあれば承認済みでなくても有効と扱う
              ## 否認の場合はチェックから除外）より過去となっていないか
              
              # 変更有無確認（変更がない場合はスルー）
              if wk_a_started_at != wk_b_started_at
                # 昨日の退社日時と昨日の終了予定時間を取得する
                attendance_yes = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on - 1)
                
                if attendance_yes.nil?
                  puts "前日のデータがないためチェックスルー" 
                else
                  puts attendance_yes.finished_at if attendance_yes.finished_at.present?
                  puts attendance_yes.end_at if attendance_yes.end_at.present? 
                  puts attendance_yes.request_end if attendance_yes.request_end.present?
                  # 翌日の出社日時の存在チェック（存在しない場合はスルー）  
                  if attendance_yes.finished_at.present?
                    # 日付チェック１（変更後の出社時間が前日の退社時間より過去となっていないか）
                    if wk_b_started_at <= attendance_yes.finished_at
                      puts "入力した出社時間が前日の退社時間より過去" # エラー処理へ
                      error_msg = "入力した出社時間が、前日の退社時間より過去であった為、残業申請をキャンセルしました。"
                      error_flg = true
                      tmp_cnt_2 += 1
                    else
                      # 前日の終了予定時間の存在チェックかつ前日の残業申請における申請ステータスチェック
                      # （終了予定時間が存在しない、または、終了予定時間が存在し申請ステータスが否認の場合はスルー）
                      if attendance_yes.end_at.present? && attendance_yes.request_end != "3" 
                        # 日付チェック２（変更後の出社時間が前日の終了予定時間より過去となっていないか）
                        if wk_b_started_at <= attendance_yes.end_at
                          puts "入力した出社時間が前日の終了予定時間より過去" # エラー処理へ
                          error_msg = "入力した出社時間が、前日の終了予定時間より過去であった為、残業申請をキャンセルしました。"
                          error_flg = true
                          tmp_cnt_2 += 1
                        end
                      end                    
                    end
                  end
                end
              end
              
              # 直前の判定処理でエラーとなっていない場合
              unless error_flg
              
                ## DB上にデータがなく、翌日のデータ申請が同時に発生していない場合
                ## 入力した退社時間が翌日の出社時間より未来となっていないか
                ## および、入力した退社時間が翌日の終了予定時間（残業申請承認済みがある）より過去となっていないか

                ## DB上にデータがなく、翌日のデータ申請が同時に発生している場合
                
                ## DB上にデータがあり、翌日のデータ申請が同時に発生していない場合

                ## DB上にデータがあり、翌日のデータ申請が同時に発生している場合

                # 変更有無確認（変更がない場合はスルー）
                if wk_a_finished_at != wk_b_finished_at
                  # 翌日の出社日時を取得
                  attendance_tom = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on + 1)

                  if attendance_tom.nil?
                    puts "翌日のデータない"
                    # 同時に翌日に勤怠変更申請の有無
                    
                    
                  else
                    puts attendance_tom.started_at
                    # 翌日の出社日時の存在チェック（存在しない場合はスルー）            
                    if attendance_tom.started_at.present?
                      # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていないか）
                      if wk_b_started_at >= attendance_tom.finished_at
                        puts "入力した退社時間が翌日の出社時間より未来" # エラー処理へ
                        error_msg = "入力した退社時間が、翌日の出社時間より未来であった為、残業申請をキャンセルしました。"
                        error_flg = true
                        tmp_cnt_2 += 1
                      end
                    end
                  end
                end
              end

              # 直前の判定処理でエラーとなっていない場合
              unless error_flg
              
                attendance.update!(started_at: wk_a_started_at,
                                   finished_at: wk_a_finished_at,
                                   note: params[:user][:attendances][id][:note],
                                   request_change: "1",
                                   ck_tomorrow_kintai: wk_ck_tomorrow
                                  ) 
                attendance_change = AttendanceChange.new(
                            worked_on: attendance.worked_on,
                            note: attendance.note,
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
                tmp_cnt += 1
              
              end
            end
          end
        end
      end
    end
    if error_flg
      # 件数の判定を入れる（変更があった申請とチェックでエラーとなった件数がイコールの場合、dangerにする）
      flash[:success] = "変更があった日時が、前日の退社時間や翌日の出社時間の相関関係が不正であった為、１部の勤怠変更申請をキャンセルしました。"
    else
      if tmp_cnt == 0
        flash[:success] = "出社日または退社日に変更箇所がなかった、または、出社日または退社日に変更したが備考または指示者確認の指定がなかったため、勤怠変更申請は未実施です。"
      else
        flash[:success] = "勤怠変更申請完了しました。"
      end
    end
    redirect_to user_url(date: params[:date], chenge_mw: params[:chenge_mw])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、勤怠変更申請をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date], chenge_mw: params[:chenge_mw])
  end

  def edit_over_work
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    @attendance = Attendance.find(params[:id])
    # 上長選択用編集処理
    user_s = User.where(superior: true)
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
  end

  def update_over_work
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    wk_ck_t = params[:attendance][:ck_tomorrow] 
    error_flg = false
    error_msg = ""
    attendance = Attendance.find(params[:id])

    # 1つめ
    # ここに退社時間と入力した終了予定時間の比較チェックを実施
    # 終了予定時間が退社時間より未来であること
    wk_finished_at = params[:finished_at]
    wk_end_at = Time.zone.parse(params[:worked_on] + " " + params[:end_at_h] + ":" + params[:end_at_m] + ":00")
    #wk_end_at = (params[:worked_on] + " " + params[:end_at_h] + ":" + params[:end_at_m] + ":00").to_time ← ZONEが効かない +0000となる
    # 翌日にチェックしていた場合
    if wk_ck_t == "1"
      wk_end_at += 86400
    end
    # 日付チェック
    if wk_finished_at >= wk_end_at
      puts "終了予定時間が退社時間より過去" # エラー処理へ
      error_msg = "入力した終了予定時間が、当日の退社時間より過去であった為、残業申請をキャンセルしました。"
      error_flg = true
    end

    # 2つめ
    # 残業申請対象日の翌日に出社時間が登録済みである場合、その出社時間と入力した終了予定時間の比較チェックを実施
    # 終了予定時間が出社時間より過去であること
    unless error_flg # 1つめのチェックがエラーがない場合
      # 翌日の出社日時を取得するため
      attendance_to = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on + 1)
      # 
      if attendance_to.started_at.present?
        puts attendance_to.started_at
        # 日付チェック
        if attendance_to.started_at <= wk_end_at
          puts "終了予定時間が翌日の出社時間より未来" # エラー処理へ
          error_msg = "入力した終了予定時間が、翌日の出社時間より未来であった為、残業申請をキャンセルしました。"
          error_flg = true
        end
      else
        puts "未設定 no_check"
      end
    end

    unless error_flg
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        #attendance = Attendance.find(params[:id])
        #wk_ck_t = params[:attendance][:ck_tomorrow]
        attendance.update!(reason: params[:attendance][:reason], 
                                        end_at: params[:end_at_h] + params[:end_at_m],
                                        ck_tomorrow: wk_ck_t,
                                        request_end: "1")
        tflg = false
        tflg = true if wk_ck_t == "1"
        puts "残１"
        @attendance = Attendance.find(params[:id])
        @attendance_end = AttendanceEnd.new(worked_on: @attendance.worked_on,
                                            end_at:  @attendance.end_at,
                                            reason: @attendance.reason,
                                            tomorrow_flg: tflg,
                                            superior_employee_number: params[:employee_number],
                                            request: "1",
                                            request_at: Time.current,
                                            user_id: @attendance.user_id,
                                            attendance_id: @attendance.id
                                            )
        puts "残２"
        @attendance_end.save!
        puts "残３"
      end
      flash[:success] = '残業申請完了しました。'
      redirect_to current_user
    else
      flash[:danger] = error_msg
      redirect_to current_user
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、残業申請をキャンセルしました。"
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
    #件数のカウント
    tmp_cnt = 0
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params2.each do |id|
        if params[:user][:attendance_ends][id][:ck_change] == "1"
          attendance_end = AttendanceEnd.find(id)
          attendance_end.update_attributes!(request: params[:user][:attendance_ends][id][:request],
                                        confirm_at: Time.current)
          attendance = Attendance.find(attendance_end.attendance_id)
          attendance.update_attributes!(request_end: params[:user][:attendance_ends][id][:request])
          tmp_cnt += 1
        end
      end
    end
    if tmp_cnt == 0
      flash[:success] = "変更項目にチェックした箇所がなかったため、残業申請を実施しませんでした。"
    else
      flash[:success] = "残業申請を更新しました。"
    end
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、残業申請をキャンセルしました。"
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
    #件数のカウント
    tmp_cnt = 0
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params3.each do |id|
        if params[:user][:attendance_changes][id][:ck_change] == "1"
          attendance_change = AttendanceChange.find(id)
          attendance_change.update_attributes!(request: params[:user][:attendance_changes][id][:request],
                                        confirm_at: Time.current)
          attendance = Attendance.find(attendance_change.attendance_id)
          attendance.update_attributes!(request_change: params[:user][:attendance_changes][id][:request])
          tmp_cnt += 1
        end
      end
    end
    if tmp_cnt == 0
      flash[:success] = "変更項目にチェックした箇所がなかったため、勤怠変更申請を実施しませんでした。"
    else
      flash[:success] = "勤怠変更申請を更新しました。"
    end
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、勤怠変更申請をキャンセルしました。"
    redirect_to current_user
  end
  
  # 勤怠ログ取得用Ajax処理
  def get_change_month
    render partial: 'select_month_change', locals: {id: params[:id]}
  end

  def edit_change_log
    # データ引継ぎ
    @first_day = params[:select_day]
    @select_area = params[:chenge_mw]
    # 初期処理
    @user = User.find(params[:id])

    # 年月プルダウン項目制御用---------------------------------------------------------------------------100
    # 勤怠変更承認済みデータを日付の昇順でソート
    atten_ymd = AttendanceChange.where(deleted_flg: false, 
                                           request: "2",
                                           user_id: params[:id]).group(:worked_on).order(:worked_on)
    
    @log_y = {}
    cnt_y = 0
    @log_m = {}
    w_y_a = "0"
    w_y_b = "0"
    w_ym_a = "0"
    w_ym_b = "0"
    w_y_hyouji = ""
    w_y_hyouji_m = ""
    w_y_genzai = "0"

    @w_cnt_y = ""
    @w_cnt_m = ""

    # 年月プルダウンのデフォルト値
    # 親画面からの起動の場合、親画面で選択していた表示年を引継ぎ設定
    if params[:gamen] == "m"
      w_y_hyouji = params[:select_day].slice(0..3)
      w_y_hyouji_m = params[:select_day]
    elsif params[:gamen] == "s"
      w_y_hyouji = params[:setday].slice(0..3)
      w_y_hyouji_m = params[:setday]
    elsif params[:gamen] == "r"
      w_y_hyouji = ""
      w_y_hyouji_m = ""
    else
      puts "tuuka"
      puts params[:user][:sec_month]
      puts params[:sec_month]
      w_y_hyouji = params[:user][:sec_month].slice(0..3)
      w_y_hyouji_m = params[:user][:sec_month].slice(0..3) + "-" + params[:user][:sec_month].slice(4..5) + "-01"
    end
    
    # 年の編集
    atten_ymd.each do |ymd|
      w_y_a = ymd.worked_on.year.to_s
      w_y_genzai = w_y_a if cnt_y == 0 # 最古の年を初期値に設定、履歴が現在日に該当する年がない場合を最古の年を画面表示のデフォルト値として設定するため
      cnt_y += 1
      if w_y_a != w_y_b
        @log_y[w_y_a] = w_y_a
        if w_y_hyouji == ""
          if w_y_hyouji == w_y_a # デフォルト値の決定
            @w_cnt_y = w_y_a
            w_y_genzai = w_y_a
          end
        end
      end
      w_y_b = w_y_a
    end
    
    # 月の編集
    m_flg = false
    atten_ymd.each do |ymd|
      w_y_a = ymd.worked_on.year.to_s
      if w_y_genzai == w_y_a
        w_ym_a = ymd.worked_on.year.to_s + format('%02d', ymd.worked_on.month)
        if w_ym_a != w_ym_b
          @log_m[w_ym_a.slice(4..6)] = w_ym_a
          tmpm = w_y_hyouji_m
          if tmpm.slice(5..6) == w_ym_a.slice(4..5) # デフォルト値の決定
            @w_cnt_m = w_ym_a
            m_flg = true
          else
            unless m_flg
              @w_cnt_m = w_ym_a
            end
          end
        end
      end
      w_ym_b = w_ym_a
    end

    # デフォルト年月より取得開始年月日と取得終了年月日を設定
    str_target_day = @w_cnt_y + @w_cnt_m + "01"
    from_target_day = str_target_day.to_date.beginning_of_month
    to_target_day = from_target_day.end_of_month
    # 一覧表示用-----------------------------------------------------------------------------------------100
    # 勤怠変更承認済みデータを取得
    @attendance_change = AttendanceChange.where(deleted_flg: false, request: "2", user_id: params[:id], worked_on: from_target_day..to_target_day)
                                         .order("worked_on ASC, request_at ASC")
    # 勤怠変更承認済みデータ件数を取得
    @attendance_change_cnt = AttendanceChange.where(deleted_flg: false, request: "2", user_id: params[:id], worked_on: from_target_day..to_target_day).count

  end

  def update_change_log
    # データ引継ぎ
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    
    puts "Start update_change_log"
    puts params[:commit]

    str_target_day = params[:user][:setday] 
    from_target_day = str_target_day.to_date.beginning_of_month
    to_target_day = from_target_day.end_of_month

    puts "勤怠ログをリセット処理開始"  
    attendance_change = AttendanceChange.all
    if attendance_change.where(user_id: params[:id],
                              worked_on: from_target_day..to_target_day,
                              request: "2",
                              deleted_flg: false
                             )
                        .update_all(deleted_at: Time.current,
                                    deleted_flg: true
                                   )

      puts "勤怠ログをリセットしました。"
      flash[:success] = str_target_day.slice(0..3) + "年" + str_target_day.slice(4..5) + "月分の勤怠ログをリセットしました。"
      #@info_message = str_target_day.slice(0..3) + "年" + str_target_day.slice(4..5) + "月分の勤怠ログをリセットしました。"
      #render :edit_change_log_success
      #render :edit_change_log_error
      #render :edit_change_log
    else
      flash[:danger] = "無効な入力データがあった為、リセットをキャンセルしました。"
    end
    redirect_to current_user, data: { dismiss: "modal"}
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
    flash[:success] = "1ヶ月分の勤怠承認申請を更新しました。"
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、1ヶ月分の勤怠承認申請をキャンセルしました。"
    redirect_to current_user
  end

  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :ck_tomorrow_kintai, :note, :employee_number])[:attendances]
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