# TaskBunnySentry

[![Hex.pm](https://img.shields.io/hexpm/l/task_bunny_sentry.svg "License")](LICENSE.md)

TaskBunny failure backend for Sentry. A port of [task_bunny_rollbar](https://github.com/shinyscorpion/task_bunny_rollbar).

## Installation

```elixir
def deps do
  [{:task_bunny_sentry, github: "Homepolish/task_bunny_sentry"}]
end
```

## Sample configuration

```elixir
config :sentry,
  dsn: "YOUR_SENTRY_DSN",
  included_environments: ~w(development),
  environment_name: "development",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{env: "development"}

config :task_bunny,
  failure_backend: [TaskBunnySentry]
```

Check [TaskBunny](https://github.com/shinyscorpion/task_bunny#failure-backends) for
more configuration options.

## Gotcha

#### Report only when the job is rejected

You might not want to report the failures which are going to be retried.
You can do it by writing a thin wrapper in your application.

```elixir
defmodule TaskBunnySentryWrapper do
  use TaskBunny.FailureBackend
  alias TaskBunny.JobError

  # reject = true means the job won't be retried.
  def report_job_error(error = %JobError{reject: true}),
    do: TaskBunnySentry.report_job_error(error)

  # otherwise ignore.
  def report_job_error(_), do: nil
end
```

Don't forget to set the wrapper module as your failure backend.

```elixir
config :task_bunny, failure_backend: [TaskBunnySentryWrapper]
```

## Copyright and License

Copyright (c) 2017, SQUARE ENIX LTD.

TaskBunnySentry code is licensed under the [MIT License](LICENSE.md).
