# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
require "webmock/rspec"
require "vcr"

OmniAuth.config.test_mode = true

# HTTP request stubbing (SRS 8.11) — specs never hit real R2. allow_localhost
# so Capybara/Selenium's own local webdriver connections still work.
WebMock.disable_net_connect!(allow_localhost: true)

# Records HTTP interactions once, replays them for processing-pipeline specs
# (SRS 8.11) — used once VideoTranscodingService gets specs (see docs/test-plan.md).
VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  # VCR replaces WebMock's own request handling once hooked in, so
  # WebMock's allow_localhost above isn't enough on its own — without this,
  # VCR intercepts Selenium's own chromedriver control-plane calls
  # (http://127.0.0.1:PORT/status) in every system spec.
  config.ignore_localhost = true
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Drives the real OmniAuth callback route with a mocked provider response
# matching an existing factory user's provider+uid, so
# User.find_or_create_from_omniauth resolves to that user rather than
# creating a new one — establishes session[:user_id] exactly the way a real
# sign-in would.
module AuthenticationHelpers
  def mock_omniauth_for(user)
    OmniAuth.config.mock_auth[user.provider.to_sym] = OmniAuth::AuthHash.new(
      provider: user.provider,
      uid: user.uid,
      info: { email: user.email, name: user.username, image: user.avatar_url }
    )
  end

  def sign_in_as(user)
    mock_omniauth_for(user)
    get auth_google_oauth2_callback_path
  end
end

# System specs drive a real browser (no get/post) — same OmniAuth mock, but
# navigated to via Capybara's visit instead.
module SystemAuthenticationHelpers
  include AuthenticationHelpers

  def sign_in_as(user)
    mock_omniauth_for(user)
    visit auth_google_oauth2_callback_path
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods
  config.include AuthenticationHelpers, type: :request
  config.include SystemAuthenticationHelpers, type: :system

  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  # Rails.cache is memory_store in test (see config/environments/test.rb) so
  # caching behavior is actually observable; clear it so one example's cached
  # values can't leak into the next. REDIS is a separate raw client (see
  # config/initializers/redis.rb) — flushed per-example for the same reason.
  config.before(:each) do
    Rails.cache.clear
    REDIS.flushdb
  end

  # Video#purge_remote_storage (an after_destroy_commit hook) makes a real R2
  # HTTP call every time a video is destroyed, which WebMock correctly blocks
  # in any spec that isn't specifically testing that behavior. Default-stub
  # it here so destroying a video in an unrelated spec (e.g. dependent-destroy
  # associations) doesn't need to know about R2 internals; specs that
  # actually exercise VideoTranscodingService/R2 override this themselves.
  config.before(:each) do
    allow(S3_BUCKET).to receive(:objects).and_return(double(batch_delete!: true)) if defined?(S3_BUCKET)
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
