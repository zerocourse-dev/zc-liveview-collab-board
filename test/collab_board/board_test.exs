defmodule CollabBoard.BoardTest do
  # The board is a shared singleton, so these tests are deliberately
  # synchronous and reset it before each one.
  use ExUnit.Case, async: false

  alias CollabBoard.Board

  setup do
    Board.reset()
    :ok
  end

  describe "add_note/3" do
    test "returns {:ok, note} with server-assigned fields" do
      assert {:ok, note} = Board.add_note(:todo, "write tests", "alice")
      assert %{id: id, text: "write tests", author: "alice", column: :todo} = note
      assert is_integer(id) and id > 0
    end

    test "accepts every valid column" do
      for column <- [:todo, :doing, :done] do
        assert {:ok, %{column: ^column}} = Board.add_note(column, "n", "a")
      end
    end

    test "rejects an unknown column" do
      assert {:error, :invalid_column} = Board.add_note(:later, "n", "a")
    end

    test "rejects empty and whitespace-only text" do
      assert {:error, :empty_text} = Board.add_note(:todo, "", "a")
      assert {:error, :empty_text} = Board.add_note(:todo, "   ", "a")
    end

    test "assigns ascending ids" do
      {:ok, first} = Board.add_note(:todo, "one", "a")
      {:ok, second} = Board.add_note(:doing, "two", "a")
      assert second.id > first.id
    end
  end

  describe "notes/0" do
    test "returns all three columns even when empty" do
      assert %{todo: [], doing: [], done: []} = Board.notes()
    end

    test "groups notes under their column in creation order" do
      {:ok, one} = Board.add_note(:todo, "one", "a")
      {:ok, two} = Board.add_note(:todo, "two", "a")
      {:ok, other} = Board.add_note(:done, "done thing", "b")

      notes = Board.notes()
      assert Enum.map(notes.todo, & &1.id) == [one.id, two.id]
      assert Enum.map(notes.done, & &1.id) == [other.id]
      assert notes.doing == []
    end
  end

  describe "move_note/2" do
    test "moves a note between columns" do
      {:ok, note} = Board.add_note(:todo, "ship it", "a")

      assert {:ok, %{column: :doing}} = Board.move_note(note.id, :doing)
      assert [%{id: id}] = Board.notes().doing
      assert id == note.id
      assert Board.notes().todo == []
    end

    test "keeps creation order in the target column" do
      {:ok, first} = Board.add_note(:doing, "first", "a")
      {:ok, second} = Board.add_note(:todo, "second", "a")
      {:ok, _} = Board.move_note(second.id, :doing)
      {:ok, third} = Board.add_note(:todo, "third", "a")
      {:ok, _} = Board.move_note(third.id, :doing)

      assert Enum.map(Board.notes().doing, & &1.id) == [first.id, second.id, third.id]
    end

    test "rejects an unknown id" do
      assert {:error, :not_found} = Board.move_note(999, :done)
    end

    test "rejects an unknown column" do
      {:ok, note} = Board.add_note(:todo, "n", "a")
      assert {:error, :invalid_column} = Board.move_note(note.id, :archived)
    end
  end

  describe "delete_note/1" do
    test "removes the note" do
      {:ok, note} = Board.add_note(:todo, "temp", "a")
      assert :ok = Board.delete_note(note.id)
      assert Board.notes().todo == []
    end

    test "returns not_found for an unknown or already-deleted id" do
      {:ok, note} = Board.add_note(:todo, "temp", "a")
      :ok = Board.delete_note(note.id)
      assert {:error, :not_found} = Board.delete_note(note.id)
      assert {:error, :not_found} = Board.delete_note(12_345)
    end
  end

  describe "PubSub broadcasts" do
    setup do
      Phoenix.PubSub.subscribe(CollabBoard.PubSub, "board")
      :ok
    end

    test "add_note broadcasts the full grouped notes" do
      {:ok, note} = Board.add_note(:todo, "hello", "a")

      assert_receive {:board_updated, %{todo: [broadcast_note]}}
      assert broadcast_note.id == note.id
    end

    test "move_note and delete_note broadcast too" do
      {:ok, note} = Board.add_note(:todo, "hello", "a")
      assert_receive {:board_updated, _}

      {:ok, _} = Board.move_note(note.id, :done)
      assert_receive {:board_updated, %{done: [_]}}

      :ok = Board.delete_note(note.id)
      assert_receive {:board_updated, %{done: []}}
    end

    test "failed mutations do not broadcast" do
      {:error, _} = Board.add_note(:todo, "", "a")
      {:error, _} = Board.move_note(999, :done)

      refute_receive {:board_updated, _}, 100
    end
  end
end
