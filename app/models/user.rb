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
    if (crypted_password == encrypt(password)) && !self.blocked? && (self.verified? || verify_ignore)
      return true
    end
    return false
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
end
