defmodule TaskBunnySentry do
  @moduledoc """
  A TaskBunny failure backend that reports to Sentry.
  """
  use TaskBunny.FailureBackend
  alias TaskBunny.JobError
  require Logger

  defexception [:message]

  def report_job_error(error = %JobError{error_type: :exception}) do
    report_error(error.exception, error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :exit}) do
    %TaskBunnySentry{message: "Unexpected exit signal"}
    |> report_error(error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :return_value}) do
    %TaskBunnySentry{message: "Unexpected return value"}
    |> report_error(System.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :timeout}) do
    %TaskBunnySentry{message: "Timeout error"}
    |> report_error(System.stacktrace, error)
  end

  def report_job_error(error = %JobError{}) do
    %TaskBunnySentry{message: "Unknown error"}
    |> report_error(System.stacktrace, error)
  end

  defp report_error(naked_exception, stacktrace, wrapped_error) do
    Logger.error inspect(wrapped_error)
    result = Sentry.capture_exception(
      naked_exception,
      [
        stacktrace: stacktrace,
        extra: %{
          job: wrapped_error.job,
          job_payload: wrapped_error.payload,
          pid: wrapped_error.pid,
          exit: wrapped_error.reason,
          return_value: inspect(wrapped_error.return_value)
        }
      ]
    )
  end
end
