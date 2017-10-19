use Mix.Config

config :sentry,
  dsn: "https://test_public_key:test_secret_key@sentry.io/00000",
  included_environments: ~w(test),
  environment_name: "test",
  tags: %{env: "test"}
