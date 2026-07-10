# Collab Board

**ZeroCourse — Elixir & Phoenix, Course 6: Phoenix LiveView — Real-Time**

A collaborative kanban board — sticky notes in three columns, every
connected user seeing every change live, an online-users list that
tracks who's here — and not one line of custom JavaScript. If you've
built this with Rails + Hotwire you wrote a Stimulus controller, a
Turbo Stream broadcast, and a partial; here the server holds the state
and the wire carries diffs. That difference is the course.

There is deliberately no database: notes live in a GenServer, because
on the BEAM a process IS state. The lesson is LiveView, not Ecto.

## What you build

Two graded surfaces (grep for `GRADED` and `NotImplementedError`):

| Surface | Where | What the tests demand |
|---------|-------|----------------------|
| The shared state | `CollabBoard.Board` | A GenServer: add/move/delete/group notes, tagged-tuple errors, and a `{:board_updated, notes}` PubSub broadcast on every successful mutation |
| The live UI | `CollabBoardWeb.BoardLive` | mount (subscribe + Presence.track), three `handle_event`s, two `handle_info`s, and a template honouring the DOM contract in the module doc |

`CollabBoardWeb.Presence` is provided; *using* it is the graded part.

## Getting started

```bash
mix deps.get
mix test          # 29 failures to turn green
mix phx.server
```

Then open **two browser windows** at
[`localhost:4000/?handle=alice`](http://localhost:4000/?handle=alice) and
[`localhost:4000/?handle=bob`](http://localhost:4000/?handle=bob) —
when your implementation works, a note added in one window appears in
the other instantly, and both handles show in the online list.

Run one surface at a time:

```bash
mix test test/collab_board/board_test.exs
mix test test/collab_board_web/live/board_live_test.exs
```

Every test fails on the fresh clone — there are no scaffolding smoke
tests in this repo.

## Tips

- The Board's `handle_call` clauses are multi-clause pattern matching
  doing the work of a controller's `if` pile. Validate first, mutate
  second, broadcast last.
- In BoardLive, the golden rule: events mutate the GenServer, the
  GenServer broadcasts, `handle_info({:board_updated, _})` re-assigns.
  Don't update `:notes` inside `handle_event` — let the broadcast do it,
  and every other user gets the same render you do.
- `Presence.list/1` returns a map keyed by whatever you passed to
  `track/4`; `Map.keys/1` is your online list. Re-read it on every
  `presence_diff`.
- Column params arrive as strings. Convert against
  `Board.columns/0` — `String.to_atom/1` on user input is a memory leak
  wearing a convenience-function costume.
- `phx-value-*` attributes become string values in your event params.

## How this is graded

CI runs the suite on every push. The full checkpoint also asks for the
comparison write-up: build the same board's essentials with Rails +
Hotwire (or reason it through honestly if you've done it before) and
write up what LiveView made easier, what it made harder, and where each
approach earns its keep. Submit it with your PR; your mentor reviews it
with the code.
