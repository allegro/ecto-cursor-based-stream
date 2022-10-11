# EctoCursorBasedStream

Cursor-based streaming of Ecto records that doesn't require database transaction.

Gives you a `cursor_based_stream/2` function that mimics `Ecto.Repo.stream/2` interface.

Advantages in comparison to standard `Ecto.Repo.stream/2`:

- streaming can be stopped and continued at any point (by passing `opts[:cursor]`),
- works with tables that have milions of records.

The only limitation is that you have to supply a _cursor column_ (by passing `opts[:cursor_column]`, defaults to `:id`). Such a column:

- must have unique values,
- should have a database index. (So that sorting by it is instant.)

## Usage

Add `ecto_cursor_based_stream` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_cursor_based_stream, "~> 0.1.0"}
  ]
end
```

Then add `use EctoCursorBasedStream` to the module that `use Ecto.Repo`:

```elixir
defmodule MyRepo do
  use Ecto.Repo
  use EctoCursorBasedStream
end
```

Then stream the rows like this:

```elixir
Post
|> MyRepo.cursor_based_stream(chunk_size: 100)
|> Stream.each(...)
|> Stream.run()
```

Docs can be found at <https://hexdocs.pm/ecto_cursor_based_stream>.

## Development

### Running tests

Run the following after cloning the repo:

```sh
mix deps.get
docker-compose up -d
mix test
```
