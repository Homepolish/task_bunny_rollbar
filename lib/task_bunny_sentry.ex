defmodule TaskBunnySentry do
  @moduledoc """
  A TaskBunny failure backend that reports to Sentry.
  """
  use TaskBunny.FailureBackend
  alias TaskBunny.JobError
  require Logger

  def report_job_error(error = %JobError{error_type: :exception}) do
    report_error :error, error.exception, error
  end

  def report_job_error(error = %JobError{error_type: :exit}) do
    report_error :exit, error.reason, error
  end

  def report_job_error(error = %JobError{error_type: :return_value}) do
    "#{error.job}: return value error"
    |> report_message(error)
  end

  def report_job_error(error = %JobError{error_type: :timeout}) do
    "#{error.job}: timeout error"
    |> report_message(error)
  end

  def report_job_error(error = %JobError{}) do
    "#{error.job}: unknown error"
    |> report_message(error)
  end

  defp report_error(kind, sentry_error, error) do
    Logger.error inspect(error)
    Sentry.capture_exception(
      sentry_error,
      [
        stacktrace: error.stacktrace || [],
        extra: %{
          kind: kind,
          custom: custom(error),
          occurrence: occurrence(error)
        }
      ]
    )
  end

  defp report_message(message, error) do
    # Provide more detail around non exceptions.
    Logger.error inspect(error)
    Sentry.capture_exception(
      message,
      [
        extra: %{
          job: error.job,
          unix_time: unix_time(),
          custom: custom(error),
          occurrence: occurrence(error)
        }
      ]
    )
  end

  defp occurrence(error) do
    %{
      "context" => error.job,
      "request" => %{
        "params" => error.payload
      }
    }
  end

  defp custom(error) do
    error
    |> Map.drop([:job, :payload, :__struct__, :exception, :stacktrace, :reason])
    |> Map.merge(%{
      meta: inspect(error.meta),
      return_value: inspect(error.return_value),
      pid: inspect(error.pid)
    })
  end

  defp unix_time() do
    {mgsec, sec, _usec} = :os.timestamp()
    mgsec * 1_000_000 + sec
  end
end
