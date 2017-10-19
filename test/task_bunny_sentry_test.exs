defmodule TaskBunnySentryTest do
  use ExUnit.Case
  alias TaskBunny.JobError
  alias TaskBunnySentry.TestJob
  import TaskBunnySentry
  import ExUnit.CaptureLog

  @job TestJob
  @payload %{"test" => true}

  describe "report_job_error/1" do
    test "handle an exception" do
      ex =
        try do
          raise "Hello"
        rescue
          e in RuntimeError -> e
        end
      error = JobError.handle_exception(@job, @payload, ex)

      assert capture_log(fn ->
        report_job_error(error)
      end) =~ ~r/RuntimeError/
    end

    test "handle the exit signal" do
      reason =
        try do
          exit(:test)
        catch
          _, reason -> reason
        end
      error = JobError.handle_exit(@job, @payload, reason)

      assert capture_log(fn ->
        report_job_error(error)
      end) =~ ~r/exit/
    end

    test "handle timeout error" do
      error = JobError.handle_timeout(@job, @payload)

      assert capture_log(fn ->
        report_job_error(error)
      end) =~ ~r/timeout/
    end

    test "handle the invlid return error" do
      error = JobError.handle_return_value(@job, @payload, {:error, :error_detail})

      assert capture_log(fn ->
        report_job_error(error)
      end) =~ ~r/error_detail/
    end
  end
end
