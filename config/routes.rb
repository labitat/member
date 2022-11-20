Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # login
  resources :session
  get "/forgot_password", to: "user#forgot_password"

  # registration
  get "/signup", to: "registration#new", as: "signup"
  post "/signup", to: "registration#create", as: "signup_create"
  get "/signup/thanks", to: "registration#thanks", as: "signup_thanks"
  get "/signup/verify", to: "registration#verify_signup", as: "verify_signup"
  get "/signup/verified", to: "registration#verify_complete", as: "verify_complete"
  get "/signup/error", to: "registration#verify_error", as: "verify_error"
  get "/signup/verify_email", to: "registration#verify_email", as: "verify_email"

  # user actions

  root "main#index"
end
