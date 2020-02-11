class AttendancesController < ApplicationController

  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :set_user2, only: [:update, :create, :edit_over_work, :update_over_work]
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_over_work]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month_or_week, only: :edit_one_month
  before_action :time_select, only: [:edit_over_work]
  before_action :gamen_ini, only: [:update_one_month]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  def new
  end

  def create
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    @user_id = params[:user_id]
    
    # 指示者確認の入力確認　入力がなければチェックおよび申請対象外
    if params[:user][:employee_number].present?
      attendance_fixs = AttendanceFix.new(
                                         worked_on: params[:m_day],
                                         superior_employee_number: params[:user][:employee_number],
                                         request: "1",
                                         request_at: Time.current,
                                         user_id: params[:user_id]
                                        )
      if attendance_fixs.save!
        flash[:success] = "所属長承認申請を行いました。"
      else
        flash[:danger] = "無効な入力データがあった為、所属長承認申請をキャンセルしました。"
      end
    else
      flash[:danger] = "上長の指定がなかったため、所属長承認申請は未実施です。"
    end
    redirect_to user_url(date: @first_day, chenge_mw: @select_area, id: @user_id)
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
    @errflg = false
  end

  def update_one_month
    #件数のカウント
    tmp_cnt = 0
    tmp_cnt_2 = 0
    error_flg = false
    @error_msg = ""
    tmp_msg = ""
    wk_cnt = 0
    gamen_input = {}
    attendances_params.each do |id|
      gamen_input[wk_cnt += 1] = id 
    end
    next_cnt = 1
    prev_cnt = -1
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        next_cnt += 1
        prev_cnt += 1
        error_flg = false
        attendance = Attendance.find(id)
        # 画面情報をテーブルに一時的に格納する
        atten_gamen = Gameninfo.new(
                    keyid: attendance.id,
                    worked_on: attendance.worked_on,
                    started_at: params[:user][:attendances][id][:started_at],
                    finished_at: params[:user][:attendances][id][:finished_at],
                    note: params[:user][:attendances][id][:note],
                    ck_tomorrow_kintai: params[:user][:attendances][id][:ck_tomorrow_kintai],
                    employee_number: params[:user][:attendances][id][:employee_number]
                    )
        atten_gamen.save!          
        # 指示者確認の入力確認　入力がなければチェックおよび申請対象外
        if params[:user][:attendances][id][:employee_number].present?
          # 出社時間かつ退社時間の入力必須チェック
          if params[:user][:attendances][id][:started_at].present? && 
            params[:user][:attendances][id][:finished_at].present? && 
            params[:user][:attendances][id][:note].present?
            # 変数設定
            wk_ck_tomorrow = params[:user][:attendances][id][:ck_tomorrow_kintai]
            wk_a_started_at = date_change(attendance.worked_on, params[:user][:attendances][id][:started_at], "s", wk_ck_tomorrow)
            wk_a_finished_at = date_change(attendance.worked_on, params[:user][:attendances][id][:finished_at], "f", wk_ck_tomorrow)
            # 終了予定時間(設定されている状態は、申請中、承認済のものとして扱う。否認、なしで設定されている場合は終了予定時間には申請前の値が設定されていることが条件)
            wk_a_end_at = nil
            if attendance.end_at.present?
              wk_a_end_at = Time.zone.parse(attendance.worked_on.to_s + " " + attendance.end_at.slice(0,2) + ":" + attendance.end_at.slice(2,2) + ":00")
              #wk_end_at = (params[:worked_on] + " " + params[:end_at_h] + ":" + params[:end_at_m] + ":00").to_time ← ZONEが効かない +0000となる
              # 翌日にチェックしていた場合
              if attendance.ck_tomorrow == "1"
                wk_a_end_at += 86400
              end
              puts "wk_a_end_at-2"
            end
            puts "wk_a_end_at-3"
            # 出社時間 < 退社時間であることのチェック
            if wk_a_started_at <= wk_a_finished_at
              # 変更前のDB情報
              wk_b_started_at = attendance.started_at
              wk_b_finished_at = attendance.finished_at
              wk_b_note = attendance.note
              wk_b_ck_tomorrow_kintai = attendance.ck_tomorrow_kintai
              # 同時入力時、該当日の翌日が勤怠変更対象の場合の入力情報
              # DB上も取得する必要がある（変更対象でないとチェックする必要がない）
              wk_next_started_at = nil
              # wk_next_finished_at = nil 未使用
              if gamen_input[next_cnt].present?
                wk_next_started_at = date_change(attendance.worked_on + 1, params[:user][:attendances][gamen_input[next_cnt]][:started_at], "s", wk_ck_tomorrow)
              # wk_next_finished_at = date_change(attendance.worked_on + 1, params[:user][:attendances][gamen_input[next_cnt]][:finished_at], "f", wk_ck_tomorrow)
              end
              wk_prev_started_at = nil
              wk_prev_finished_at = nil
              if prev_cnt > 0
                wk_prev_started_at = date_change(attendance.worked_on - 1, params[:user][:attendances][gamen_input[prev_cnt]][:started_at], "s", wk_ck_tomorrow)
                wk_prev_finished_at = date_change(attendance.worked_on - 1, params[:user][:attendances][gamen_input[prev_cnt]][:finished_at], "f", wk_ck_tomorrow)
              end

              # 変更有無確認チェック
              if wk_a_started_at != wk_b_started_at || wk_a_finished_at != wk_b_finished_at # 差異がある
                ## 入力した出社時間が前日の退社時間より過去となっていないか
                ## および、入力した出社時間が前日の終了予定時間（残業申請中でもあれば承認済みでなくても有効と扱う
                ## 否認の場合はチェックから除外）より過去となっていないか
              
                # 出社時間における変更有無確認（変更がない場合はスルー）
                if wk_a_started_at != wk_b_started_at
                  # 変更対象日前日の退社時間と変更対象日前日の終了予定時間を取得する
                  attendance_yes = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on - 1)
                
                  if attendance_yes.nil?
                    # puts "前日の既存データがない"
                    if wk_prev_finished_at.nil?
                      # puts "前日の申請データがないためチェックスルー"
                    else
                      # puts "前日の申請データがある"
                      if wk_a_finished_at < wk_prev_finished_at
                        # puts "入力した出社時間が前日の申請データの退社時間より過去1"
                        @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) + 
                          "】入力した出社時間が、前日の申請データの退社時間より過去であったため、申請をキャンセルしました。1"
                        atten_gamen.update_attributes!(error_msg: @error_msg)
                        error_flg = true
                        tmp_cnt_2 += 1                      
                      else
                        # puts "正常：入力出社日時 ≧ 前日申請データの出社日時"
                      end
                    end
                  else
                    # puts "前日のデータがある"
                    # 変更対象日前日の退社時間の存在チェック（存在しない場合はスルー、前日出社していない場合にあり得る）
                    if attendance_yes.finished_at.present?
                      # 日付チェック１
                      # (1) 同時に前日のデータを申請していた場合、先に更新しているため申請データとの比較はしない
                      # (2) 変更後の出社時間が前日の退社時間より過去となっていないか
                      # (3) 前日の終了予定時間の存在有無
                      #     ⇒終了予定時間が存在しない場合は、以降の処理はスルー
                      #       残業申請有無にかかわらず、設定されていれば有効とする
                      # (4) 変更後の出社時間が前日の終了予定時間より過去となっていないか
  
                      if wk_a_started_at <= attendance_yes.finished_at # (2)
                        # puts "入力した出社時間が前日の退社時間より過去2" # エラー処理へ
                        @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) + 
                          "】入力した出社時間が、前日の退社時間より過去であったため、申請をキャンセルしました。2"
                        atten_gamen.update_attributes!(error_msg: @error_msg)
                        error_flg = true
                        tmp_cnt_2 += 1
                      else
                        # 前日の終了予定時間の存在チェックかつ前日の残業申請における申請ステータスチェック
                        # （終了予定時間が存在しない、または、終了予定時間が存在し申請ステータスが否認の場合はスルー）
                        if attendance_yes.end_at.present? # (3)
                          # 日付チェック２（変更後の出社時間が前日の終了予定時間より過去となっていないか）
                          # 終了予定日(end_at)を文字列型から日付型に変換
                          wk_end_at = date_change2(attendance_yes.worked_on, attendance_yes.end_at, "f", attendance_yes.ck_tomorrow, false)
                          puts "前日の終了予定時間と当日の出社時間の比較"
                          puts wk_a_started_at
                          puts wk_end_at
                          if wk_a_started_at <= wk_end_at # (4)
                            # puts "入力した出社時間が前日の終了予定時間より過去3" # エラー処理へ
                            @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                              "】入力した出社時間が、前日の終了予定時間より過去であったため、申請をキャンセルしました。3"
                            atten_gamen.update_attributes!(error_msg: @error_msg)
                            error_flg = true
                            tmp_cnt_2 += 1
                          end
                        end                    
                      end
                    else
                      # puts "前日の既存データに退社日時がない"
                      if wk_prev_finished_at.nil?
                        # puts "前日の申請データがないためチェックスルー"
                      else
                        # puts "前日の申請データがある"
                        if wk_a_started_at < wk_prev_finished_at
                          # puts "入力した出社時間が前日の申請データの退社時間より過去4"
                          @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                            "】入力した出社時間が、前日の申請データの退社時間より過去であったため、申請をキャンセルしました。4"
                          atten_gamen.update_attributes!(error_msg: @error_msg)
                          error_flg = true
                          tmp_cnt_2 += 1                      
                        else
                          # puts "正常：入力出社日時 ≧ 前日申請データの出社日時"
                        end
                      end
                    end
                  end
                else
                  # puts "出社日時における変更なし"
                end
                # 直前の判定処理でエラーとなっていない場合
                unless error_flg
                  ## DB上にデータがなく、翌日のデータ申請が同時に発生していない場合
                  ## 入力した退社時間が翌日の出社時間より未来となっていないか
                  ## および、入力した退社時間が翌日の終了予定時間（残業申請承認済みがある）より過去となっていないか
                  ## DB上にデータがなく、翌日のデータ申請が同時に発生している場合
                  ## DB上にデータがあり、翌日のデータ申請が同時に発生していない場合
                  ## DB上にデータがあり、翌日のデータ申請が同時に発生している場合
                  # 退社日時における変更有無確認（変更がない場合はスルー）
                  if wk_a_finished_at != wk_b_finished_at
                    if wk_a_end_at.present? 
                      if wk_a_finished_at > wk_a_end_at
                        error_flg = true
                        @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                          "】入力した退社時間が終了予定時間より未来であったため、申請をキャンセルしました。"
                        atten_gamen.update_attributes!(error_msg: @error_msg)
                        error_flg = true
                        tmp_cnt_2 += 1
                      end
                    end
                    unless error_flg
                      # 翌日の出社日時を取得
                      attendance_tom = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on + 1)
                      # 同時に翌日に勤怠変更申請の有無
                      if wk_next_started_at.present?
                        # puts "翌日の申請データあり"
                        # 翌日の出社日時の存在チェック（存在しない場合はスルー）            
                        if attendance_tom.nil?
                          # puts "attendance_tom no-data"
                          # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていない）
                          if wk_a_finished_at >= wk_next_started_at
                            # puts "入力した退社時間が翌日分申請の出社時間より未来5" # エラー処理へ
                            @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                              "】入力した退社時間が、翌日分申請の出社時間より未来であったため、申請をキャンセルしました。5"
                            atten_gamen.update_attributes!(error_msg: @error_msg)
                            error_flg = true
                            tmp_cnt_2 += 1
                          end
                        else
                          if attendance_tom.started_at.present?
                            # puts attendance_tom.started_at
                            # 翌日の申請データと登録済データを比較し変更有無を確認する                    
                            if wk_next_started_at != attendance_tom.started_at
                              # puts "翌日のデータに差異あり"
                              # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていないか）
                              if wk_a_finished_at >= wk_next_started_at
                                # puts "入力した退社時間が翌日分申請の出社時間より未来6" # エラー処理へ
                                @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                                  "】入力した退社時間が、翌日分申請の出社時間より未来であったため、申請をキャンセルしました。6"
                                atten_gamen.update_attributes!(error_msg: @error_msg)
                                error_flg = true
                                tmp_cnt_2 += 1
                              end
                            else
                              # puts "翌日のデータに差異なし"
                              # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていないか）
                              if wk_a_finished_at >= attendance_tom.started_at
                                # puts "入力した退社時間が翌日の出社時間より未来7" # エラー処理へ
                                @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                                  "】入力した退社時間が、翌日の出社時間より未来であったため、申請をキャンセルしました。7"
                                atten_gamen.update_attributes!(error_msg: @error_msg)
                                error_flg = true
                                tmp_cnt_2 += 1
                              end
                            end
                          else
                            # puts "attendance_tom.started_at no-data"
                            # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていないか）
                            if wk_a_finished_at >= wk_next_started_at
                              # puts "入力した退社時間が翌日分申請の出社時間より未来8" # エラー処理へ
                              @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                                "】入力した退社時間が、翌日分申請の出社時間より未来であったため、申請をキャンセルしました。8"
                              atten_gamen.update_attributes!(error_msg: @error_msg)
                              error_flg = true
                              tmp_cnt_2 += 1
                            end
                          end
                        end
                      else
                        # puts "翌日の申請データなし"
                        # 翌日の出社日時の存在チェック（存在しない場合はスルー）            
                        if attendance_tom.nil?
                          # チェックなし
                        else
                          if attendance_tom.started_at.present?
                            # puts attendance_tom.started_at
                            # 日付チェック（変更後の退社時間が翌日の出社時間より未来となっていないか）
                            if wk_a_finished_at >= attendance_tom.started_at
                              # puts "入力した退社時間が翌日の出社時間より未来9" # エラー処理へ
                              @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) +
                                "】入力した退社時間が、翌日の出社時間より未来であったため、申請をキャンセルしました。9"
                              atten_gamen.update_attributes!(error_msg: @error_msg)
                              error_flg = true
                              tmp_cnt_2 += 1
                            end
                          else
                            # チェックなし
                          end
                        end
                      end
                    end
                  else
                    # puts "退社日時における変更なし"    
                  end
                else
                  # puts "出社時間にエラーがあったため、退社時間のチェックはしない"
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
                              before_note: wk_b_note,
                              before_ck_tomorrow_kintai: wk_b_ck_tomorrow_kintai,
                              superior_employee_number: params[:user][:attendances][id][:employee_number],
                              request: "1",
                              request_at: Time.current,
                              user_id: attendance.user_id,
                              attendance_id: attendance.id)
                  attendance_change.save!
                  atten_gamen.update_attributes!(normal_msg: "\n 【日付：" + l(attendance.worked_on, format: :short) + "】勤怠変更申請を完了しました。")
                  tmp_cnt += 1
                end
              else # 変更有無確認チェック
                @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) + "】出社時間および退社時間に変更がありません。"
                atten_gamen.update_attributes!(error_msg: @error_msg)
                tmp_cnt_2 += 1
              end # 変更有無確認チェック 
            else # 出社時間 < 退社時間であることのチェック
              @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) + "】出社時間が退社時間より未来になっています。"
              atten_gamen.update_attributes!(error_msg: @error_msg)
              tmp_cnt_2 += 1              
            end # 出社時間 < 退社時間であることのチェック
          else # 出社時間かつ退社時間の入力必須チェック
            tmp_msg = ""
            unless params[:user][:attendances][id][:started_at].present? 
              tmp_msg += "出社時間、"
            end
            unless params[:user][:attendances][id][:finished_at].present?
              tmp_msg += "退社時間、"
            end
            unless params[:user][:attendances][id][:note].present?
              tmp_msg += "備考、"
            end
            tmp_msg = tmp_msg.chop
            @error_msg = "\n 【日付：" + l(attendance.worked_on, format: :short) + "】" + tmp_msg + "に入力がありません。"
            atten_gamen.update_attributes!(error_msg: @error_msg)
            tmp_cnt_2 += 1
          end # 出社時間かつ退社時間の入力必須チェック
        end # 指示者確認の入力確認　入力がなければチェックおよび申請対象外
      end
      if tmp_cnt_2 > 0
        if tmp_cnt > 0
          # 件数の判定を入れる（変更があった申請とチェックでエラーとなった件数がイコールの場合、dangerにする）
          tmp_msg = "勤怠変更申請対象に入力エラーが、" + tmp_cnt_2.to_s + "件あります。"
          tmp_msg += "<br> 一部正常に処理した申請があったため、" + tmp_cnt.to_s + "件申請しました。"
          flash[:danger] = tmp_msg
        else
          # 件数の判定を入れる（変更があった申請とチェックでエラーとなった件数がイコールの場合、dangerにする）
          flash[:danger] = "勤怠変更申請対象に入力エラーが、" + tmp_cnt_2.to_s + "件あります。"
        end
        redirect_to attendances_edit_one_month_user_url(date: params[:date], chenge_mw: params[:chenge_mw], inflg: true)
      else
        if tmp_cnt == 0
          flash[:info] = "指示者確認の指定がなかったため、勤怠変更申請は未実施です。"
        else
          flash[:success] = tmp_cnt.to_s + "件の勤怠変更申請を完了しました。"
        end
        redirect_to user_url(date: params[:date], chenge_mw: params[:chenge_mw])
      end
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによ通信等のエラー分岐です。
    flash[:danger] = "無効な入力データがあったため、勤怠変更申請をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date], chenge_mw: params[:chenge_mw], inflg: true)
  end

  def edit_over_work
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    @user_id = params[:user_id]
    @attendance = Attendance.find(params[:id])
    # 上長選択用編集処理(アクセスユーザー本人は除く（上長権限保有していた場合）)
    user_s = User.where(superior: true).where.not(id: params[:user_id])
    @user_superior = {}
    user_s.each do |u|
      @user_superior[u.name] = u.employee_number
    end
  end

  def update_over_work
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    @user_id = params[:user_id]
    wk_ck_t = params[:attendance][:ck_tomorrow] 
    error_flg = false
    @errflg = false
    error_msg = ""
    attendance = Attendance.find(params[:id])
    wk_finished_at = params[:finished_at]
    wk_end_at_b = attendance.end_at
    wk_end_at_a = params[:end_at_h] + params[:end_at_m]
    wk_ck_t_b = attendance.ck_tomorrow
    # 1つめ
    # 入力した終了予定時間が前回申請時の内容と同じでないこと
    if wk_end_at_b == wk_end_at_a && wk_ck_t_b == wk_ck_t
      # puts "終了予定時間が前回申請時と同じ内容" # エラー処理へ
      error_msg = "入力した終了予定時間が、前回申請時の内容と同じあった為、残業申請をキャンセルしました。"
      error_flg = true
    end
    # 2つめ
    # ここに退社時間と入力した終了予定時間の比較チェックを実施
    # 終了予定時間が退社時間より未来であること
    unless error_flg # 1つめのチェックがエラーがない場合
      wk_end_at = Time.zone.parse(params[:worked_on] + " " + params[:end_at_h] + ":" + params[:end_at_m] + ":00")
      #wk_end_at = (params[:worked_on] + " " + params[:end_at_h] + ":" + params[:end_at_m] + ":00").to_time ← ZONEが効かない +0000となる
      # 翌日にチェックしていた場合
      if wk_ck_t == "1"
        wk_end_at += 86400
      end
      # 日付チェック
      if wk_finished_at >= wk_end_at
        # puts "終了予定時間が退社時間より過去" # エラー処理へ
        error_msg = "入力した終了予定時間が、当日の退社時間より過去であった為、残業申請をキャンセルしました。"
        error_flg = true
      end
    end
    # 3つめ
    # 残業申請対象日の翌日に出社時間が登録済みである場合、その出社時間と入力した終了予定時間の比較チェックを実施
    # 終了予定時間が出社時間より過去であること
    unless error_flg # 2つめのチェックがエラーがない場合
      # 翌日の出社日時を取得するため
      attendance_to = Attendance.find_by(user_id: attendance.user_id, worked_on: attendance.worked_on + 1)
      # 
      if attendance_to.started_at.present?
        # puts attendance_to.started_at
        # 日付チェック
        if attendance_to.started_at <= wk_end_at
          # puts "終了予定時間が翌日の出社時間より未来" # エラー処理へ
          error_msg = "入力した終了予定時間が、翌日の出社時間より未来であった為、残業申請をキャンセルしました。"
          error_flg = true
        end
      else
        # puts "未設定 no_check"
      end
    end
    unless error_flg
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        @attendance_b = Attendance.find(params[:id])
        #wk_ck_t = params[:attendance][:ck_tomorrow]
        
        attendance.update!(reason: params[:attendance][:reason], 
                                        end_at: params[:end_at_h] + params[:end_at_m],
                                        ck_tomorrow: wk_ck_t,
                                        request_end: "1")
        tflg = false
        tflg = true if wk_ck_t == "1"
        @attendance = Attendance.find(params[:id])
        @attendance_end = AttendanceEnd.new(worked_on: @attendance.worked_on,
                                            end_at:  @attendance.end_at,
                                            reason: @attendance.reason,
                                            tomorrow_flg: tflg,
                                            superior_employee_number: params[:employee_number],
                                            request: "1",
                                            request_at: Time.current,
                                            user_id: @attendance.user_id,
                                            attendance_id: @attendance.id,
                                            before_end_at: @attendance_b.end_at,
                                            tomorrow_flg_before: @attendance_b.ck_tomorrow,
                                            before_reason: @attendance_b.reason
                                            )
        @attendance_end.save!
      end
      flash[:success] = '残業申請完了しました。'
      redirect_to user_url(date: @first_day, chenge_mw: @select_area, id: @user_id)
    else
      flash[:danger] = error_msg
      redirect_to user_url(date: @first_day, chenge_mw: @select_area, id: @user_id)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、残業申請をキャンセルしました。"
    redirect_to user_url(date: @first_day, chenge_mw: @select_area, id: @user_id)
  end

  def edit_end_ck
    @user = User.find(params[:id])
    @attendance_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_end = AttendanceEnd.where(superior_employee_number: current_user.employee_number, request: "1").group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_end_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    # 閉じるボタンを押下された場合は処理しない。
    if params[:commit] != "閉じる"
      #件数のカウント
      tmp_cnt = 0
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        attendances_params2.each do |id|
          if params[:user][:attendance_ends][id][:ck_change] == "1" # 変更にチェックしている場合
            wk_req = params[:user][:attendance_ends][id][:request]
            attendance_end = AttendanceEnd.find(id)
            attendance_end.update_attributes!(request: wk_req, confirm_at: Time.current)
            attendance = Attendance.find(attendance_end.attendance_id)
            if wk_req == "3" # 否認した場合、attendanceを前の情報で更新
              setflg = "0"
              if attendance_end.tomorrow_flg_before
                setflg = "1"
              end
              attendance.update_attributes!(
                request_end: params[:user][:attendance_ends][id][:request],
                end_at: attendance_end.before_end_at,
                ck_tomorrow: setflg,
                reason: attendance_end.before_reason)            
            else
              attendance.update_attributes!(request_end: params[:user][:attendance_ends][id][:request])
            end
            tmp_cnt += 1
          end
        end
      end
      if tmp_cnt == 0
        flash[:info] = "変更項目にチェックした箇所がなかったため、残業申請の更新は実施しませんでした。"
      else
        flash[:success] = "残業申請を更新しました。"
      end
    end
    redirect_to current_user
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、残業申請をキャンセルしました。"
    redirect_to current_user
  end

  def edit_change_ck
    @user = User.find(params[:id])
    @attendance_change = AttendanceChange.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_change = AttendanceChange.where(superior_employee_number: current_user.employee_number, request: "1").group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_change_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    # 閉じるボタンを押下された場合は処理しない。
    if params[:commit] != "閉じる"
      #件数のカウント
      tmp_cnt = 0
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        attendances_params3.each do |id|
          if params[:user][:attendance_changes][id][:ck_change] == "1"
            attendance_change = AttendanceChange.find(id)
            attendance = Attendance.find(attendance_change.attendance_id)
            if params[:user][:attendance_changes][id][:request] == "0" || params[:user][:attendance_changes][id][:request] == "3" 
              # なし、否認の場合、申請前の情報で更新する
              # 変更前情報で更新
              attendance.update_attributes!(
                started_at: attendance_change.before_started_at ,
                finished_at: attendance_change.before_finished_at ,
                note: attendance_change.before_note ,
                request_change: params[:user][:attendance_changes][id][:request],
                ck_tomorrow_kintai: attendance_change.before_ck_tomorrow_kintai)
              attendance_change.update_attributes!(request: params[:user][:attendance_changes][id][:request],
                                            confirm_at: Time.current)
              tmp_cnt += 1
            elsif params[:user][:attendance_changes][id][:request] == "2"
              attendance_change.update_attributes!(request: params[:user][:attendance_changes][id][:request],
                                            confirm_at: Time.current)
              attendance.update_attributes!(request_change: params[:user][:attendance_changes][id][:request])
              tmp_cnt += 1
            end
          end
        end
      end
      if tmp_cnt == 0
        flash[:info] = "変更項目にチェックした箇所がなかったため、勤怠変更申請の更新は実施しませんでした。"
      else
        flash[:success] = "勤怠変更申請を更新しました。"
      end
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
    str_target_day = params[:user][:setday] 
    from_target_day = str_target_day.to_date.beginning_of_month
    to_target_day = from_target_day.end_of_month
    # puts "勤怠ログをリセット処理開始"  
    attendance_change = AttendanceChange.all
    if attendance_change.where(user_id: params[:id],
                              worked_on: from_target_day..to_target_day,
                              request: "2",
                              deleted_flg: false
                             )
                        .update_all(deleted_at: Time.current,
                                    deleted_flg: true
                                   )
      # puts "勤怠ログをリセットしました。"
      flash[:success] = str_target_day.slice(0..3) + "年" + str_target_day.slice(4..5) + "月分の勤怠ログをリセットしました。"
    else
      flash[:danger] = "無効な入力データがあった為、リセットをキャンセルしました。"
    end
    redirect_to current_user, data: { dismiss: "modal"}
  end

  def edit_fix_ck
    @user = User.find(params[:id])
    @attendance_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number, request: "1").order("worked_on DESC, user_id ASC")
    @user_fix = AttendanceFix.where(superior_employee_number: current_user.employee_number, request: "1").group(:user_id).order(:user_id)
    @req_sec = { :"なし" => "0", :"申請中" => "1", :"承認" => "2", :"否認" => "3" }
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
  end

  def update_fix_ck
    @first_day = params[:date]
    @select_area = params[:chenge_mw]
    # 閉じるボタンを押下された場合は処理しない。
    if params[:commit] != "閉じる"
      tmp_cnt = 0
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        attendances_params4.each do |id|
          if params[:user][:attendance_fixs][id][:ck_change] == "1"
            attendance_fix = AttendanceFix.find(id)
            attendance_fix.update_attributes!(request: params[:user][:attendance_fixs][id][:request],
                                              confirm_at: Time.current)
            tmp_cnt += 1
          end
        end
      end
  
      if tmp_cnt == 0
        flash[:info] = "変更項目にチェックした箇所がなかったため、1ヶ月分の勤怠承認を実施しませんでした。"
      else
        flash[:success] = "1ヶ月分の勤怠承認申請を更新しました。"
      end
    end
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
          
          wk_started_at = attendance.started_at
          wk_finished_at = attendance.finished_at
          wk_note = attendance.note
          wk_working_times_at = working_times_at(wk_started_at, wk_finished_at),
          if attendance.request_change == "1"
            wk_started_at = nil
            wk_finished_at = nil
            wk_note = nil
          end
          wk_working_times_at = working_times_at(wk_started_at, wk_finished_at)
          column_values = [
            attendance.worked_on,
            $days_of_the_week[attendance.worked_on.wday],
            set_times_at(wk_started_at),
            set_times_at(wk_finished_at),
            wk_working_times_at,
            wk_note
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

end