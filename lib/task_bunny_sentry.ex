defmodule TaskBunnySentry do
  @moduledoc """
  A TaskBunny failure backend that reports to Sentry.
  """
  use TaskBunny.FailureBackend
  require Logger
  alias TaskBunny.JobError

  @type task :: {:ok, Task.t()} | :error | :excluded | :ignored

  @spec report_job_error(error :: JobError.t(), opts :: [extra: list(atom)]) :: task
  def report_job_error(error = %JobError{error_type: :exception}, opts = [extra: _]) do
    report_error(error.exception, error.stacktrace, error, opts)
  end

  @spec report_job_error(error :: JobError.t()) :: task
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

  ## PRIVATE FUNCTIONS

  defp original_stacktrace(stacktrace) do
    chunks = stacktrace |> elem(1) |> Enum.chunk_by(&(elem(&1, 0) == TaskBunnySentry))
    Enum.at(chunks, 1) ++ Enum.at(chunks, 2)
  end

  defp report_error(naked_exception, stacktrace, wrapped_error, opts \\ []) do
    extra =
      naked_exception
      |> Map.take(Keyword.get(opts, :extra, []))
      |> Map.merge(%{
        meta: inspect(wrapped_error.meta),
        job: wrapped_error.job,
        job_payload: wrapped_error.payload,
        pid: inspect(wrapped_error.pid),
        exit: wrapped_error.reason,
        return_value: inspect(wrapped_error.return_value)
      })

    with {:ok, _event_id} = result <-
           Sentry.capture_exception(naked_exception, stacktrace: stacktrace, extra: extra) do
      result
    else
      {:error, reason} ->
        Logger.error("#{__MODULE__}: Could not send error to upstream.
          JobError: #{inspect(naked_exception)} : #{inspect(extra)}
          Reason: #{inspect(reason)}")

        :error

      err ->
        Logger.error("#{__MODULE__}: unexpected error sending to upstream.
          JobError: #{inspect(naked_exception)} : #{inspect(extra)}
          Reason: #{inspect(err)}")

        :error
    end
  end
end
