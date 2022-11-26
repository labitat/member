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

  # root
  root "main#index"
end
