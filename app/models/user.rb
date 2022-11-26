require "securerandom"

class User < ApplicationRecord
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.generate_random_password(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    (0...len).map { chars[SecureRandom.random_number(chars.length)] }.join
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password, verify_ignore = false)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password, verify_ignore = verify_ignore) ? u : nil
  end

  validates_presence_of :password, :if => :password_required?
  validates_presence_of :password_confirmation, :if => :password_required?
  validates_length_of :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?

  has_many :payments

  before_create :encrypt_password

  # plaintext password not saved in db
  attr_accessor :password, :password_confirmation

  before_destroy :do_before_destroy

  scope :unblocked, lambda { where("blocked = 0") }
  scope :marked_as_paying, lambda { where("will_pay = 1") }
  scope :blocked, lambda { "blocked = 1" }
  scope :verified, lambda { "verified = 1 AND blocked = 0" }
  scope :unverified, lambda { "verified = 0 AND blocked = 0" }

  validates_presence_of :email, :message => "You must supply an email address"
  validates_presence_of :name, :message => "You must write your name"
  validates_presence_of :login, :message => "You must choose a login. This will be your Labitat nickname"
  validates_uniqueness_of :login, :case_sensitive => false, :message => "The chosen login is in use by another Labitat member"
  validates_length_of :login, :within => 2..32, :too_short => "Your login is too short (minimum 3 characters)", :too_long => "Your login is too long (maximum 16 characters)"
  validates_uniqueness_of :email, :case_sensitive => false, :message => "A user with the supplied email address already exists"
  validates_confirmation_of :password, :message => "Repeated password did not match password"

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password, verify_ignore = false)
    (ActiveSupport::SecurityUtils.secure_compare(crypted_password, encrypt(password))) && !self.blocked? && (self.verified? || verify_ignore)
  end

  def password_required?
    crypted_password.blank? || !password.nil?
  end

  def verify!
    self.auth_code = ""
    self.verified = true
    self.verified_date = Time.now.strftime("%Y-%m-%d")
    self.email = email.downcase
    on_verify # run on_verify hooks
    self.save!
  end

  def on_verify

    # irc_register_account
    #mailman_register_all if mailing_list?

    begin
      mediawiki_register_account unless mediawiki_user_exists?
    rescue Exception => e
      p e
      Rails.logger.error(e)
      # reverse mailman signup and irc account creation before failing
      mailman_unregister_all if mailing_list?
      irc_drop_account
      raise e
    end
  end

  def mailman_register_all

    #lists = mailman_getlists
    # mailman_register("members")

    #lists.keys.each do |list|
    #  unless lists[list]
    #    mailman_register(list)
    #  end
    #end
  end

  def mailman_register(list = "members")
    if Rails.configuration.mailman_path.present?
      return true
    end

    #list = 'members' # XXX list name should be in settings.yml, not hardcoded here
    if list == "announce"
      list = "members"
    end

    ENV["PYTHONPATH"] = "#{Rails.configuration.mailman_path}/bin"
    ENV["PYTHONPATH"] += ":" + "#{RAILS_ROOT}/script/mailman"

    withlist = "#{Rails.configuration.mailman_path}/bin/withlist -l -r"
    passwordparam = "--password " + User.generate_random_password(10) # random pw
    passwordparam = "--password #{password.shellescape}" if password
    script = "#{withlist} new_member #{list.shellescape} --email #{email.shellescape} #{passwordparam}"

    out = `#{script} 2>&1`

    if out.match(/error/i)
      if out.match(/exists/i) # email is already registered
        return mailman_change_password(list) # update the password
      else
        raise out
      end
    else
      return true
    end
  end

  def mailman_unregister_all
    lists = mailman_getlists

    lists.keys.each do |list|
      if lists[list]
        mailman_unregister(false, list)
      end
    end
  end

  def mailman_getlists
    if !Rails.configuration.mailman_path.present?
      return true
    end

    ENV["PYTHONPATH"] = Settings["mailman_path"] + "/bin"
    ENV["PYTHONPATH"] += ":" + RAILS_ROOT + "/script/mailman"

    script = Settings["mailman_path"] + "/bin/list_lists -b"
    out = `#{script} 2>&1`

    lists = Hash.new
    list_members = Settings["mailman_path"] + "/bin/list_members"

    out.split("\n").each do |list|
      if list == "mailman" or list == "bestyrelse" or list == "info" or list == "rf13makerspace" or list == "biologigaragenboard" or list == "trustees" # ignore the mailman meta-list and the sekrit board list
        next
      end
      script = "#{list_members}  #{list}"
      outinner = `#{script} 2>&1`

      found = false
      outinner.split("\n").each do |line|
        if line == email
          found = true
          break
        end
      end

      storeas = list
      if list == "members"
        storeas = "announce"
      end
      lists[storeas] = found
    end

    return lists
  end

  def mailman_unregister(p_email = false, list = "members")
    if !Settings["mailman_path"]
      return true
    end

    use_email = p_email || email

    if list == "announce"
      list = "members"
    end

    ENV["PYTHONPATH"] = Settings["mailman_path"] + "/bin"
    ENV["PYTHONPATH"] += ":" + RAILS_ROOT + "/script/mailman"

    withlist = Settings["mailman_path"] + "/bin/withlist -l -r"
    script = "#{withlist} delete_member #{list.shellescape} --email #{use_email.shellescape}"

    out = `#{script} 2>&1`

    if out.match(/error/i)
      raise out
    else
      return true
    end
  end

  def mediawiki_user_exists?
    if !Rails.configuration.mediawiki_path.present?
      return true
    end

    ENV["MW_INSTALL_PATH"] = Rails.configuration.mediawiki_path
    script_path = "#{RAILS_ROOT}/script/mediawiki"

    out = `php #{script_path}/user_check.php -- #{login.shellescape}` # is the username free?

    if $?.success?
      return false
    else
      return true
    end
  end

  def mediawiki_same_password?
    if Rails.configuration.mediawiki_path.present?
      return true
    end

    ENV["MW_INSTALL_PATH"] = Rails.configuration.mediawiki_path
    script_path = RAILS_ROOT + "/script/mediawiki"

    out = `php #{script_path}/login_check.php -- #{login.shellescape} #{password.shellescape}` # is the password valid for the mediawiki user?

    if $?.success?
      return true
    else
      return false
    end
  end

  def mediawiki_register_account
    if Rails.configuration.mediawiki_path.present?
      return true
    end

    ENV["MW_INSTALL_PATH"] = Rails.configuration.mediawiki_path
    script_path = RAILS_ROOT + "/script/mediawiki"

    out = `php #{script_path}/create_user.php -- #{login.shellescape} #{password.shellescape} #{email.shellescape}` # create a mediawiki user

    if $?.success?
      return true
    else
      raise "Mediawiki user creation error: " + out
    end
  end

  def generate_forgot_password_token!
    self.forgot_password_token = User.generate_random_password(40)
    self.forgot_password_expires = (Time.now + 60 * 60 * 4) # 4h expire
    self.save!
  end

  def change_password!(new_password)
    self.password = new_password
    self.password_confirmation = new_password

    encrypt_password

    #    irc_change_password # XXX not working
    mailman_change_password if mailing_list?
    mediawiki_change_password

    self.forgot_password_token = nil
    self.forgot_password_expires = nil
    self.save!
  end

  def mailman_change_password(list = "members")
    if Rails.configuration.mailman_path.present?
      return true
    end

    #list = 'members'
    if list == "announce"
      list = "members"
    end

    ENV["PYTHONPATH"] = "#{Rails.configuration.mailman_path}/bin:#{Rails.root}/script/mailman"

    #      withlist = Settings['mailman_path'] + "/bin/withlist -l -r"
    #      script = "#{withlist} set_member_password #{list} --email #{email} --password #{password}"

    script = "#{Rails.root}/script/mailman/set_member_password.py --list #{list} --email #{email.shellescape} --password #{password.shellescape}"

    out = `#{script} 2>&1`

    if out.match(/error/i)
      raise out
    else
      return true
    end
  end

  def mediawiki_change_password
    if Rails.configuration.mediawiki_path.present?
      return true
    end

    ENV["MW_INSTALL_PATH"] = Rails.configuration.mediawiki_path
    script_path = "#{Rails.root}/script/mediawiki"

    out = `php #{script_path}/change_password.php -- #{login.shellescape} #{password.shellescape}` # change password for mediawiki user

    if $?.success?
      return false
    else
      return true
    end
  end

  # is the user an admin?
  def is_admin?
    if self.group == "admin"
      return true
    else
      return false
    end
  end

  def forget_me!
    self.remember_token_expires_at = nil
    self.remember_token = nil
    save!
  end

  def paying?
    fmt = "%Y-%m-%d"
    today = Date.strptime(Time.now.strftime(fmt), fmt)

    if !paid_until
      return false
    end

    if paid_until >= today
      return true
    end

    return false
  end

  def ever_paid?
    fmt = "%Y-%m-%d"
    epoch = Date.strptime("1970-01-01", fmt)

    if !paid_until
      return false
    end

    if paid_until > epoch
      return true
    else
      return false
    end
  end
end
