# TaskBunnySentry

[![Hex.pm](https://img.shields.io/hexpm/l/task_bunny_sentry.svg "License")](LICENSE.md)

TaskBunny failure backend for Sentry. A port of [task_bunny_rollbar](https://github.com/shinyscorpion/task_bunny_rollbar).

## Installation

```elixir
def deps do
  [{:task_bunny_sentry, "~> 0.1.3"}]
end
```

## Configuration

```elixir
config :task_bunny,
  failure_backend: [TaskBunnySentry]
```

Check [TaskBunny](https://github.com/shinyscorpion/task_bunny#failure-backends) for
more configuration options.

## Customization

### Report only rejected

Sometimes it's best to report only when the job has entered a rejected state.
To do this, one can write a wrapper around the reporting module, pattern matting on the `JobError`.

```elixir
defmodule TaskBunnySentryWrapper do
  use TaskBunny.FailureBackend
  alias TaskBunny.JobError

  # Match only on rejected state
  def report_job_error(error = %JobError{reject: true}),
    do: TaskBunnySentry.report_job_error(error)

  # Otherwise ignore
  def report_job_error(_), do: nil
end
```

### Passing additional exception fields

For instances where one needs to pass additional meta information, a wrapper and be similarly used
to extract values from the exception struct.

```elixir
defmodule FooError do
  defexception([:message, :foo, :fizz])
end

defmodule TaskBunnySentryWrapper do
  use TaskBunny.FailureBackend
  alias TaskBunny.JobError

  # Define the props to be collected from FooError
  def report_job_error(error = %JobError{exception: %FooError{}}),
    do: TaskBunnySentry.report_job_error(error, extra: [:foo, :fizz])

  # Otherwise delegate
  def report_job_error(error), do: TaskBunnySentry.report_job_error(error)
end
```

> **Note:** When using a wrapper module, it must be set as the failure backend.
>
```elixir
config :task_bunny, failure_backend: [TaskBunnySentryWrapper]
```

## Copyright and License

Copyright (c) 2018 Homepolish, Inc.

TaskBunnySentry code is licensed under the [MIT License](LICENSE.md).
