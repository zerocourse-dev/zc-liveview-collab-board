defmodule CollabBoard.JsonFormatter do
  @moduledoc """
  ExUnit formatter that outputs RSpec-compatible JSON to test-results.json.
  Used by GitHub Actions CI for the ZeroCourse grading pipeline.

  You never need to touch this file.
  """
  use GenServer

  def init(_opts) do
    {:ok, %{examples: [], summary: nil}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, state) do
    example = %{
      description: test.name |> to_string(),
      full_description: "#{inspect(test.module)} #{test.name}",
      status: status(test.state),
      file_path: test.tags.file,
      line_number: test.tags.line,
      run_time: test.time / 1_000_000,
      exception: exception_info(test.state)
    }

    {:noreply, %{state | examples: [example | state.examples]}}
  end

  # ExUnit >= 1.12 sends {:suite_finished, times_us} where times_us is
  # %{run: _, async: _, load: _} — there is NO :failures key, so we count
  # failures from the examples we collected ourselves.
  def handle_cast({:suite_finished, times_us}, state) when is_map(times_us) do
    total = length(state.examples)
    passed = Enum.count(state.examples, &(&1.status == "passed"))
    failures = Enum.count(state.examples, &(&1.status == "failed"))

    result = %{
      version: "ZeroCourse ExUnit JSON Formatter",
      examples: Enum.reverse(state.examples),
      summary: %{
        duration: (times_us[:run] || 0) / 1_000_000,
        example_count: total,
        failure_count: failures,
        pending_count: total - passed - failures
      },
      summary_line: "#{total} examples, #{failures} failures"
    }

    File.write!("test-results.json", Jason.encode!(result, pretty: true))
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  defp status(nil), do: "passed"
  defp status({:failed, _}), do: "failed"
  defp status({:skipped, _}), do: "pending"
  defp status({:excluded, _}), do: "pending"
  defp status({:invalid, _}), do: "failed"
  defp status(_), do: "failed"

  defp exception_info({:failed, failures}) do
    failures
    |> Enum.map(fn
      {_, %{message: msg}} -> msg
      _ -> "unknown error"
    end)
    |> Enum.join("\n")
  end

  defp exception_info(_), do: nil
end
