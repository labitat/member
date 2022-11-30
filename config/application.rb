require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Member
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.session_store(
      :cookie_store,
      key: "_socializus_session",
      httponly: true,
    )

    config.member_fee = 150
    config.doorputer_verify_max_delay = 240
    config.doorputer_key = ""
    config.radius_key = ""
    config.mailman_path = ""
    config.mediawiki_path = ""
    config.mediawiki_url = ""
    config.atheme_server = ""
  end
end
