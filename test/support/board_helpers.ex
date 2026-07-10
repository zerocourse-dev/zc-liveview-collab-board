defmodule CollabBoard.BoardHelpers do
  @moduledoc """
  Shared test helpers. Don't edit this file.
  """

  @doc """
  Polls `fun` every 10ms until it returns a truthy value or `timeout`
  milliseconds elapse; returns the last value either way. Use it for
  eventually-consistent assertions (cross-session renders, presence).
  """
  def eventually(fun, timeout \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    poll(fun, deadline)
  end

  defp poll(fun, deadline) do
    result = fun.()

    if result || System.monotonic_time(:millisecond) >= deadline do
      result
    else
      Process.sleep(10)
      poll(fun, deadline)
    end
  end
end
