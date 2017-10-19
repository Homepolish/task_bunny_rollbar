use Mix.Config

# If you want to try this library with your Sentry account
# unncomment the below and set your access token.
#

#config :sentry,
#  dsn: "YOUR_SENTRY_DSN",
#  included_environments: ~w(development),
#  environment_name: "development",
#  enable_source_code_context: true,
#  root_source_code_path: File.cwd!,
#  tags: %{env: "development"}

#config :task_bunny,
#  failure_backend: [TaskBunnySentry],
#  hosts: [
#    default: [connect_options: []]
#  ],
#  queue: [
#    namespace: "task_bunny.sentry.",
#    queues: [
#      [name: "normal", jobs: :default]
#    ]
#  ]

import_config "#{Mix.env}.exs"
