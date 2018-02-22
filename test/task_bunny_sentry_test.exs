defmodule TaskBunnySentryTest do
  use ExUnit.Case, async: true

  import Mox

  alias TaskBunny.JobError
  alias TaskBunnySentry.TestJob

  setup :set_mox_from_context
  setup :verify_on_exit!

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

      expect(SentryMock, :send_event, fn %Sentry.Event{event_id: id} = event, _ ->
        assert event.exception == [%{module: nil, type: RuntimeError, value: "Hello"}]
        assert event.extra == %{
          exit: nil,
          job: TaskBunnySentry.TestJob,
          job_payload: %{"test" => true},
          meta: "%{}",
          pid: "nil",
          return_value: "nil"
        }

        {:ok, Task.async(fn -> {:ok, id} end)}
      end)

      {:ok, task} = TaskBunnySentry.report_job_error(error)
      {:ok, event_id} = Task.await(task)

      assert Regex.match?(~r/^[a-f0-9]{32}$/, event_id)
    end

    test "handle an exception with extra properties" do
      defmodule FooError do
        defexception([:message, :foo, :fizz])
      end
      ex =
        try do
          raise FooError, message: "Foo", foo: "bar", fizz: "buzz"
        rescue
          e in FooError -> e
        end

      error = JobError.handle_exception(@job, @payload, ex)

      expect(SentryMock, :send_event, fn %Sentry.Event{event_id: id} = event, _ ->
        assert event.exception == [%{module: nil, type: FooError, value: "Foo"}]
        assert event.extra == %{
          exit: nil,
          job: TaskBunnySentry.TestJob,
          job_payload: %{"test" => true},
          meta: "%{}",
          pid: "nil",
          return_value: "nil",
          foo: "bar"
        }

        {:ok, Task.async(fn -> {:ok, id} end)}
      end)

      {:ok, task} = TaskBunnySentry.report_job_error(error, extra: [:foo])
      {:ok, event_id} = Task.await(task)

      assert Regex.match?(~r/^[a-f0-9]{32}$/, event_id)
    end

    test "handle the exit signal" do
      reason =
        try do
          exit(:test)
        catch
          _, reason -> reason
        end
      error = JobError.handle_exit(@job, @payload, reason)

      expect(SentryMock, :send_event, fn %Sentry.Event{event_id: id} = event, _ ->
        assert event.exception == [%{module: nil, type: TaskBunnyError, value: "Unexpected exit signal"}]
        assert event.extra == %{
          exit: :test,
          job: TaskBunnySentry.TestJob,
          job_payload: %{"test" => true},
          meta: "%{}",
          pid: "nil",
          return_value: "nil"
        }

        {:ok, Task.async(fn -> {:ok, id} end)}
      end)

      {:ok, task} = TaskBunnySentry.report_job_error(error)
      {:ok, event_id} = Task.await(task)

      assert Regex.match?(~r/^[a-f0-9]{32}$/, event_id)
    end

    test "handle timeout error" do
      error = JobError.handle_timeout(@job, @payload)

      expect(SentryMock, :send_event, fn %Sentry.Event{event_id: id} = event, _ ->
        assert event.exception == [%{module: nil, type: TaskBunnyError, value: "Timeout error"}]
        assert event.extra == %{
          exit: nil,
          job: TaskBunnySentry.TestJob,
          job_payload: %{"test" => true},
          meta: "%{}",
          pid: "nil",
          return_value: "nil"
        }

        {:ok, Task.async(fn -> {:ok, id} end)}
      end)

      {:ok, task} = TaskBunnySentry.report_job_error(error)
      {:ok, event_id} = Task.await(task)

      assert Regex.match?(~r/^[a-f0-9]{32}$/, event_id)
    end

    test "handle the invlid return error" do
      error = JobError.handle_return_value(@job, @payload, {:error, :error_detail})

      expect(SentryMock, :send_event, fn %Sentry.Event{event_id: id} = event, _ ->
        assert event.exception == [%{module: nil, type: TaskBunnyError, value: "Unexpected return value"}]
        assert event.extra == %{
          exit: nil,
          job: TaskBunnySentry.TestJob,
          job_payload: %{"test" => true},
          meta: "%{}",
          pid: "nil",
          return_value: "{:error, :error_detail}"
        }

        {:ok, Task.async(fn -> {:ok, id} end)}
      end)

      {:ok, task} = TaskBunnySentry.report_job_error(error)
      {:ok, event_id} = Task.await(task)

      assert Regex.match?(~r/^[a-f0-9]{32}$/, event_id)
    end
  end
end
