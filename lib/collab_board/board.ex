defmodule CollabBoard.Board do
  @moduledoc """
  The shared board. GRADED.

  One GenServer holds every note — no database, deliberately: the lesson
  is real-time state, and a process IS state on the BEAM. It is already
  started in the supervision tree under the name `CollabBoard.Board`.

  ## The note

  A plain map: `%{id: pos_integer, text: String.t(), author: String.t(),
  column: :todo | :doing | :done}`. Ids are assigned by the server,
  ascending from 1.

  ## The contract (pinned by the tests)

    * `notes/0` always returns `%{todo: [...], doing: [...], done: [...]}` —
      all three keys present even when empty, each list in creation order
      (ascending id), moves do not reshuffle.
    * Every successful mutation broadcasts `{:board_updated, notes()}` on
      the `"board"` topic of `CollabBoard.PubSub` — that is how every
      LiveView hears about every other user's change.
    * Errors are tagged tuples, never raises: `{:error, :invalid_column}`,
      `{:error, :empty_text}` (empty or whitespace-only), `{:error, :not_found}`.

  The starter state in `init/1` is a suggestion — reshape it if your
  implementation wants something else.
  """

  use GenServer

  @columns [:todo, :doing, :done]

  def columns, do: @columns

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok) do
    {:ok, %{notes: [], next_id: 1}}
  end

  @doc """
  Adds a note. GRADED.

  Returns `{:ok, note}` — or `{:error, :invalid_column}` /
  `{:error, :empty_text}` (reject `""` and whitespace-only text).
  Broadcasts on success.
  """
  def add_note(column, text, author) do
    _ = {column, text, author}

    raise "NotImplementedError: implement add_note/3"
  end

  @doc """
  Moves a note to another column. GRADED.

  Returns `{:ok, note}` — or `{:error, :not_found}` /
  `{:error, :invalid_column}`. Broadcasts on success.
  """
  def move_note(id, to_column) do
    _ = {id, to_column}

    raise "NotImplementedError: implement move_note/2"
  end

  @doc """
  Deletes a note. GRADED.

  Returns `:ok` — or `{:error, :not_found}`. Broadcasts on success.
  """
  def delete_note(id) do
    _ = id

    raise "NotImplementedError: implement delete_note/1"
  end

  @doc """
  All notes, grouped by column. GRADED. See the module doc for the shape.
  """
  def notes do
    raise "NotImplementedError: implement notes/0"
  end

  @doc """
  Empties the board. GRADED (the test suite calls this between tests).
  """
  def reset do
    raise "NotImplementedError: implement reset/0"
  end
end
