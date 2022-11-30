module Admin::MoneyHelper
  def payment_user_list(users, selected_id, count = nil)
    name = (count) ? "payment[#{count}][user_id]" : "payment[user_id]"
    select_tag name, options_for_select([["&#60;ignore&#62;", "0"]] + users.map { |u| [u.login, u.id.to_s] }, selected_id ? selected_id.to_s : "0")
  end
end
