Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # login
  get "/session/new", to: "session#new", as: "new_session"
  post "/session/new", to: "session#create"
  get "/session/destroy", to: "session#destroy", as: "session_destory"

  # password
  get "/forgot_password", to: "registration#forgot_password", as: "forgot_password"
  post "/forgot_password", to: "registration#send_forgot_password_email"
  get "/forgot_password_sent", to: "registration#forgot_password_sent", as: "forgot_password_sent"
  get "/change_password", to: "registration#change_password", as: "change_password"
  post "/change_password", to: "registration#update_password"

  # registration
  get "/signup", to: "registration#new", as: "signup"
  post "/signup", to: "registration#create", as: "signup_create"
  get "/signup/thanks", to: "registration#thanks", as: "signup_thanks"
  get "/signup/verify", to: "registration#verify", as: "verify_signup"
  post "/signup/verify", to: "registration#verify_signup"
  get "/signup/verified", to: "registration#verify_signup_complete", as: "verify_complete"
  get "/signup/error", to: "registration#verify_error", as: "verify_error"
  get "/signup/verify_email", to: "registration#verify_email", as: "verify_email"

  # user actions
  get "/user/info", to: "user#info", as: "user_info"
  get "/user/radius_hashes", to: "user#radius_hashes", as: "radius_hashes"

  get "/user/hashes", to: "user#list_hashes", as: "user_hashes"
  get "/user/claim_hash/:id", to: "user#claim_hash", as: "claim_hash"
  get "/user/clear_hash", to: "user#clear_hash", as: "clear_hash"
  get "/user/payment_info", to: "user#payment_info", as: "payment_info"

  # door
  get "/money/doorputer_new_hash", to: "door#new_hash", as: "new_door_hash"
  get "/money/doorputer_get_dates", to: "door#list", as: "door_hash_list"

  # admin
  namespace :admin do
    # user
    get "/users", to: "user#list"
    # money
    get "/money", to: "money#index"
    get "/money/upload", to: "money#upload"
    post "/money/confirm_bankdata", to: "money#confirm_bankdata"
    post "/money/save_bankdata", to: "money#save_bankdata"
    get "/money/stats", to: "money#stats"
    get "/money/new", to: "money#new_payment"
    post "/money/new", to: "money#create_payment"
    get "/money/edit/:id", to: "money#edit_payment", as: "money_edit"
    post "/money/edit/:id", to: "money#update_payment"
    get "/money/search", to: "money#search_payments", as: "search_payments"
    get "/money/results", to: "money#payment_search_results", as: "search_results"
  end

  # root
  root "user#index"
end
