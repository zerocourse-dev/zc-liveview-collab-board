defmodule CollabBoardWeb.BoardLive do
  @moduledoc """
  The collaborative board. GRADED.

  Everything real-time flows through here:

    * `mount/3` — when `connected?(socket)`: subscribe to the `"board"`
      PubSub topic, subscribe to `"presence:board"`, and track this user
      via `CollabBoardWeb.Presence`. The user's handle comes from the
      `"handle"` query param (`/?handle=alice`) or defaults to a random
      `"user-XXXX"`. Assign `:handle`, `:notes` (from
      `CollabBoard.Board.notes/0`), `:online` (list of handles), and
      `:error` (nil).
    * `handle_event/3` — `"add_note"` (params `%{"text" => _, "column" => _}`,
      author is the socket's handle; a failed add puts the reason in the
      `:error` assign, a successful one clears it), `"move_note"`
      (`%{"id" => _, "to" => _}`), `"delete_note"` (`%{"id" => _}`).
      Column/id params arrive as strings — convert against
      `CollabBoard.Board.columns/0`, never `String.to_atom/1`.
    * `handle_info/2` — `{:board_updated, notes}` re-assigns `:notes`;
      `%Phoenix.Socket.Broadcast{event: "presence_diff"}` re-reads the
      presence list.

  ## DOM contract (pinned by the tests — keep these ids and bindings)

    * `#my-handle` shows the user's own handle
    * `#online-users` contains one `[data-handle]` element per user online
    * `#column-todo` / `#column-doing` / `#column-done` wrap each column
    * each note renders as `#note-<id>` inside its column, showing text
      and author, with buttons bound to `phx-click="move_note"`
      (`phx-value-id`, `phx-value-to`) and `phx-click="delete_note"`
      (`phx-value-id`)
    * the add form is `<form phx-submit="add_note">` with a `text` input
      and a `column` select
    * `#board-error` renders the current `:error` assign when present

  No custom JavaScript anywhere — that is the whole point.
  """

  use CollabBoardWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    _ = {params, session, socket}

    raise "NotImplementedError: implement mount/3"
  end

  @impl true
  def handle_event(event, params, socket) do
    _ = {event, params, socket}

    raise "NotImplementedError: implement handle_event/3 for add_note/move_note/delete_note"
  end

  @impl true
  def handle_info(message, socket) do
    _ = {message, socket}

    raise "NotImplementedError: implement handle_info/2 for :board_updated and presence_diff"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="board">
      <p>
        TODO: replace this placeholder with the board — the DOM contract
        is in the module doc. You own this template.
      </p>
    </div>
    """
  end
end
