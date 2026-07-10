defmodule CollabBoardWeb.BoardLiveTest do
  use CollabBoardWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import CollabBoard.BoardHelpers

  alias CollabBoard.Board

  setup do
    Board.reset()
    :ok
  end

  defp join(conn, handle) do
    {:ok, view, _html} = live(conn, ~p"/?handle=#{handle}")
    view
  end

  describe "mount and render" do
    test "renders all three columns", %{conn: conn} do
      view = join(conn, "alice")
      html = render(view)

      assert html =~ ~s(id="column-todo")
      assert html =~ ~s(id="column-doing")
      assert html =~ ~s(id="column-done")
    end

    test "shows the handle from the query param", %{conn: conn} do
      view = join(conn, "alice")
      assert element(view, "#my-handle") |> render() =~ "alice"
    end

    test "assigns a random user- handle when none is given", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert element(view, "#my-handle") |> render() =~ "user-"
    end

    test "renders notes that already exist at mount", %{conn: conn} do
      {:ok, note} = Board.add_note(:doing, "already here", "bob")

      view = join(conn, "alice")
      assert element(view, "#column-doing #note-#{note.id}") |> render() =~ "already here"
    end
  end

  describe "add_note" do
    test "adding a note renders it in its column with the author", %{conn: conn} do
      view = join(conn, "alice")

      view
      |> form("form[phx-submit=add_note]", %{"text" => "try liveview", "column" => "todo"})
      |> render_submit()

      note_html = element(view, "#column-todo") |> render()
      assert note_html =~ "try liveview"
      assert note_html =~ "alice"
    end

    test "empty text renders an error and adds nothing", %{conn: conn} do
      view = join(conn, "alice")

      view
      |> form("form[phx-submit=add_note]", %{"text" => "   ", "column" => "todo"})
      |> render_submit()

      assert has_element?(view, "#board-error")
      assert Board.notes().todo == []
    end

    test "a successful add clears a previous error", %{conn: conn} do
      view = join(conn, "alice")

      view
      |> form("form[phx-submit=add_note]", %{"text" => "", "column" => "todo"})
      |> render_submit()

      assert has_element?(view, "#board-error")

      view
      |> form("form[phx-submit=add_note]", %{"text" => "real note", "column" => "todo"})
      |> render_submit()

      refute has_element?(view, "#board-error")
    end
  end

  describe "move_note and delete_note" do
    test "moving a note re-renders it in the target column", %{conn: conn} do
      {:ok, note} = Board.add_note(:todo, "movable", "bob")
      view = join(conn, "alice")

      view
      |> element("#note-#{note.id} [phx-click=move_note][phx-value-to=doing]")
      |> render_click()

      assert has_element?(view, "#column-doing #note-#{note.id}")
      refute has_element?(view, "#column-todo #note-#{note.id}")
    end

    test "deleting a note removes it", %{conn: conn} do
      {:ok, note} = Board.add_note(:done, "old", "bob")
      view = join(conn, "alice")

      view
      |> element("#note-#{note.id} [phx-click=delete_note]")
      |> render_click()

      refute has_element?(view, "#note-#{note.id}")
    end
  end

  describe "collaboration across sessions" do
    test "a note added in one session appears in another without reload", %{conn: conn} do
      alice = join(conn, "alice")
      bob = join(build_conn(), "bob")

      alice
      |> form("form[phx-submit=add_note]", %{"text" => "seen everywhere", "column" => "todo"})
      |> render_submit()

      assert eventually(fn -> render(bob) =~ "seen everywhere" end)
    end

    test "a move in one session updates the other", %{conn: conn} do
      {:ok, note} = Board.add_note(:todo, "shared", "carol")
      alice = join(conn, "alice")
      bob = join(build_conn(), "bob")

      alice
      |> element("#note-#{note.id} [phx-click=move_note][phx-value-to=done]")
      |> render_click()

      assert eventually(fn -> has_element?(bob, "#column-done #note-#{note.id}") end)
    end
  end

  describe "presence" do
    test "both online users appear in both sessions", %{conn: conn} do
      alice = join(conn, "alice")
      bob = join(build_conn(), "bob")

      assert eventually(fn ->
               html = render(alice)
               html =~ "alice" and html =~ "bob"
             end)

      assert eventually(fn ->
               online = element(bob, "#online-users") |> render()
               online =~ "alice" and online =~ "bob"
             end)
    end

    test "a user who leaves disappears from the online list", %{conn: conn} do
      alice = join(conn, "alice")
      bob = join(build_conn(), "bob")

      assert eventually(fn -> element(alice, "#online-users") |> render() =~ "bob" end)

      # Killing the LiveView process is the "closed the tab" signal.
      GenServer.stop(bob.pid)

      assert eventually(fn ->
               not (element(alice, "#online-users") |> render() =~ "bob")
             end)
    end
  end
end
