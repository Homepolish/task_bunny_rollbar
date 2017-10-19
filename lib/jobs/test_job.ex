defmodule TaskBunnySentry.TestJob do
  @moduledoc false
  #
  # Handy sample job to try out the error reporting with TaskBunny.
  #
  use TaskBunny.Job

  def max_retry, do: 1
  def timeout, do: 1_000

  def perform(payload) do
    if payload["sleep"], do: :timer.sleep(payload["sleep"])

    if payload["exception"] do
      raise "Testing exception"
    end

    if payload["exit"] do
      exit :testing
    end

    if payload["fail"] do
      :error
    else
      :ok
    end
  end
end
