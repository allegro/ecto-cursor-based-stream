# EctoCursor

Cursor-based streaming of Ecto records, that does not require database transaction.

Advantages in comparison to the standard `Ecto.Repo.stream/2`:

- streaming can be stopped and continued at any point (by passing option `after_cursor: ...`),
- works with tables that have milions of records.

Only limitation is that you have to supply a _cursor column or columns_ (by passing option `cursor_field: ...`, defaults to `:id`). Such a column(s):

- must have unique values,
- should have a database index. (So that sorting by it, and returning a number of rows larger than `x` is a performant operation.)

## Usage

1. Add `ecto_cursor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_cursor, "~> 1.1.0"}
  ]
end
```

2. Add `use EctoCursor` to the module that uses `Ecto.Repo`:

```elixir
defmodule MyRepo do
  use Ecto.Repo
  use EctoCursor
end
```

3. Stream the rows using `cursor_stream/2`:

```elixir
Post
|> MyRepo.cursor_stream(max_rows: 100)
|> Stream.each(...)
|> Stream.run()
```

4. Query if you don't want to stream

```elixir
{posts, next_cursor} = MyRepo.cursor_query(Post, cursor_field: [published_at: :desc, id: :desc])
```
