require "csv"
require "date"

class Payment < ApplicationRecord
  belongs_to :user

  def self.parse_payment(row)
    payment = self.new

    payment.comment = row[1]
    payment.received = Date.strptime(row[0], "%d-%m-%Y")
    payment.amount = row[2].gsub(".", "").gsub(",", ".").to_f

    payment.detect_user

    return payment
  end

  def self.parse_payments(csv_data)
    rows = CSV.parse(csv_data, col_sep: ?;)

    if !rows
      return []
    end

    payments = []
    rows.each_with_index do |row, i|
      next if i == 0 && row[0] == "Dato"
      payments << parse_payment(row)
    end
    payments.sort! do |a, b|
      a.received <=> b.received
    end

    return payments
  end

  # attempt to detect and associate a user, based on the comment field
  def detect_user
    # try to match login (which can only contain numbers and letters) or name

    nameq = "%" + comment.gsub(/[^\w\d]/, "%") + "%"
    if nameq.length < 4
      nameq = nil
    end

    login = false
    m = comment.scan(/[\w\d]+/)
    m.each do |substr|
      if substr.length >= 2
        login = substr.downcase
        break
      end
    end

    user = nil

    loginq = "%" + login + "%"
    if login && nameq
      user = User.where(["lower(login) = ?", login]).first || User.where(["lower(login) like ? OR lower(name) like ?", loginq, nameq]).first
    elsif login
      user = User.where(["lower(login) = ? OR lower(login) like ?", login, loginq]).first
    elsif nameq
      user = User.where(["lower(name) like ?", nameq]).first
    end

    # attempt to match against existing payments based on comment
    if !user
      payments = Payment.where(["comment = ?", comment])
      if payments.length > 0
        same_user = payments[0].user
        payments.each do |payment|
          if payment.user != same_user
            same_user == nil
            break
          end
        end
        if same_user
          user = same_user
        end
      end
    end

    if user
      self.user_id = user.id
      return user
    end

    return false
  end

  def find_dupe
    self.class.where(["comment = ? AND received = ? AND amount = ?", comment, received, amount]).first
  end
end
