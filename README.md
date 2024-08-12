# EctoCursorBasedStream

![Build Status](https://img.shields.io/github/actions/workflow/status/allegro/ecto-cursor-based-stream/test.yml) [![Hex.pm](https://img.shields.io/hexpm/v/ecto_cursor_based_stream.svg)](https://hex.pm/packages/ecto_cursor_based_stream) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/ecto_cursor_based_stream/)

Cursor-based streaming of Ecto records, that does not require database transaction.

Gives you a [`cursor_based_stream/2`](https://hexdocs.pm/ecto_cursor_based_stream/EctoCursorBasedStream.html#c:cursor_based_stream/2) function that mimics [`Ecto.Repo.stream/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2) interface.

Advantages in comparison to the standard `Ecto.Repo.stream/2`:

- streaming can be stopped and continued at any point (by passing option `after_cursor: ...`),
- works with tables that have milions of records.

Only limitation is that you have to supply a _cursor column or columns_ (by passing option `cursor_field: ...`, defaults to `:id`). Such a column:

- must have unique values,
- should have a database index. (So that sorting by it, and returning a number of rows larger than `x` is a performant operation.)

## Usage

1. Add `ecto_cursor_based_stream` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_cursor_based_stream, "~> 1.2.0"}
  ]
end
```

2. Add `use EctoCursorBasedStream` to the module that uses `Ecto.Repo`:

```elixir
defmodule MyRepo do
  use Ecto.Repo
  use EctoCursorBasedStream
end
```

3. Stream the rows using `cursor_based_stream/2`:

```elixir
Post
|> MyRepo.cursor_based_stream()
|> Stream.each(...)
|> Stream.run()
```

## Useful links

- [Documentation](https://hexdocs.pm/ecto_cursor_based_stream/EctoCursorBasedStream.html)
- [Examples](https://github.com/allegro/ecto-cursor-based-stream/blob/main/test/ecto_cursor_based_stream_test.exs)

## Contributing

### Running tests

Run the following after cloning the repo:

```sh
mix deps.get
docker-compose up -d
mix test
```
