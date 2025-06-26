import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

config :max_gallery, MaxGallery.Repo,
  database: "datas_test",
  username: "admin",       
  password: "admin",       
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :max_gallery, MaxGalleryWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ofctNIe9eHhk4Lze19rRooX2QSF2PZvbfge+3vJY0drjG537g1Osk43TwhjICk2h",
  server: false

# In test we don't send emails
config :max_gallery, MaxGallery.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
