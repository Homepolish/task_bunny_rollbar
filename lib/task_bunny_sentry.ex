defmodule TaskBunnySentry do
  @moduledoc """
  A TaskBunny failure backend that reports to Sentry.
  """
  use TaskBunny.FailureBackend
  
  alias TaskBunny.JobError

  def report_job_error(error = %JobError{error_type: :exception}) do
    report_error(error.exception, error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :exit}) do
    %TaskBunnyError{message: "Unexpected exit signal"}
    |> report_error(error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :return_value}) do
    %TaskBunnyError{message: "Unexpected return value"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  def report_job_error(error = %JobError{error_type: :timeout}) do
    %TaskBunnyError{message: "Timeout error"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  def report_job_error(error = %JobError{}) do
    %TaskBunnyError{message: "Unknown error"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  defp original_stacktrace(stacktrace) do
    chunks = stacktrace |> elem(1) |> Enum.chunk_by(&(elem(&1, 0) == TaskBunnySentry))
    Enum.at(chunks, 1) ++ Enum.at(chunks, 2)
  end

  defp report_error(naked_exception, stacktrace, wrapped_error) do
    Sentry.capture_exception(
      naked_exception,
      [
        stacktrace: stacktrace,
        extra: %{
          meta: inspect(wrapped_error.meta),
          job: wrapped_error.job,
          job_payload: wrapped_error.payload,
          pid: inspect(wrapped_error.pid),
          exit: wrapped_error.reason,
          return_value: inspect(wrapped_error.return_value)
        }
      ]
    )
  end
end
