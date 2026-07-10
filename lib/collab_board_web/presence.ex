defmodule CollabBoardWeb.Presence do
  @moduledoc """
  Standard Phoenix.Presence — provided scaffolding, already in the
  supervision tree. BoardLive is where you USE it (that part is graded):
  track each connected user on the `"presence:board"` topic and turn
  `presence_diff` broadcasts into an up-to-date online list.
  """
  use Phoenix.Presence,
    otp_app: :collab_board,
    pubsub_server: CollabBoard.PubSub
end
