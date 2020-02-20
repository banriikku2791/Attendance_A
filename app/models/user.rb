class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :attendance_changes, dependent: :destroy
  has_many :attendance_ends, dependent: :destroy
  has_many :attendance_fixs, dependent: :destroy
  
  #accepts_nested_attributes_for :attendance_ends
  # accepts_nested_attributes_for :attendance_ends, ck_change: 0
  
  attr_accessor :sec_year
  attr_accessor :sec_month
  
  # 「remember_token」という仮想の属性を作成します。
  attr_accessor :remember_token
  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :affiliation, length: { in: 2..50 }, allow_blank: true
  validates :basic_time, presence: true
  validates :work_time, presence: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  # validates :employee_number, uniqueness: true,
  validates :employee_number, numericality: true
  validates :admin, inclusion: { in: [true, false] }
  validates :superior, inclusion: { in: [true, false] }

  # 渡された文字列のハッシュ値を返します。
  def User.digest(string)
    cost = 
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返します。
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためハッシュ化したトークンをデータベースに記憶します。
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # トークンがダイジェストと一致すればtrueを返します。
  def authenticated?(remember_token)
    # ダイジェストが存在しない場合はfalseを返して終了します。
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄します。
  def forget
    update_attribute(:remember_digest, nil)
  end

  def self.search(search)
    if search
      where(['name Like ?', "%#{search}%"])
    else
      all
    end
  end

  #def self.import(file)
  #  CSV.foreach(file.path, headers: true) do |row|

  #    obj = new
  #    obj.attributes = row.to_hash.slice(*updatable_attributes)

  #    obj.save!
  #  end
  #end

  #def self.updatable_attributes
  #  ["name","email","affiliation","employee_number","uid","basic_work_time",
  #    "designated_work_start_time","designated_work_end_time","superior","admin","password"]
  #end

end