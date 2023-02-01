defmodule EctoCursorBasedStream do
  @moduledoc """
  Use this module in any module that uses `Ecto.Repo`
  to enrich it with `cursor_based_stream/2` function.

  Example:

      defmodule MyRepo do
        use Ecto.Repo
        use EctoCursorBasedStream
      end

      MyUser
      |> MyRepo.cursor_based_stream(chunk_size: 100)
      |> Stream.each(...)
      |> Stream.run()
  """

  @type cursor_based_stream_opts :: [
          {:chunk_size, integer()}
          | {:cursor, String.t() | integer()}
          | {:cursor_field, atom()}
        ]

  @doc """
  Return a lazy enumerable that emits all entries from the data store
  matching the given query.

  In contrast to `Ecto.Repo.stream/2`,
  this will not use database mechanisms (e.g. database transactions) to stream the rows.

  It does so by sorting all the rows by `options[:cursor_field]`
  and iterating over them in chunks of size `options[:max_rows]`.

  ## Options

  * `:cursor_field` - the field by which all rows should be iterated.

    **This field must have unique values. (Otherwise, some rows may get skipped.)**

    For performance reasons, we recommend that you have an index on that field. Defaults to `:id`.

  * `:after_cursor` - the value of the `:cursor_field` must be greater than it.

    Useful when you want to continue streaming from a certain point.
    Any rows with value equal or smaller than this value will not be included.

    Defaults to `nil`. (All rows will be included.)

  * `:max_rows` - The number of rows to load from the database as we stream.

    Defaults to 500.

  ## Example

      MyUser
      |> MyRepo.cursor_based_stream(chunk_size: 100)
      |> Stream.each(...)
      |> Stream.run()
  """
  @callback cursor_based_stream(Ecto.Queryable.t(), cursor_based_stream_opts) :: Enum.t()

  defmacro __using__(_) do
    quote do
      @behaviour EctoCursorBasedStream

      @impl EctoCursorBasedStream
      def cursor_based_stream(queryable, options \\ []) do
        EctoCursorBasedStream.call(__MODULE__, queryable, options)
      end
    end
  end

  @doc false
  def call(repo, queryable, options \\ []) do
    %{max_rows: max_rows, after_cursor: after_cursor, cursor_field: cursor_field} =
      parse_options(options)

    Stream.unfold(after_cursor, fn cursor ->
      case get_rows(repo, queryable, cursor_field, cursor, max_rows) do
        [] ->
          nil

        rows ->
          next_cursor = get_last_row_cursor(rows, cursor_field)
          {rows, next_cursor}
      end
    end)
    |> Stream.flat_map(& &1)
  end

  defp parse_options(options) do
    max_rows = Keyword.get(options, :max_rows, 500)
    after_cursor = Keyword.get(options, :after_cursor)
    cursor_field = Keyword.get(options, :cursor_field, :id)

    %{
      max_rows: max_rows,
      after_cursor: after_cursor,
      cursor_field: cursor_field
    }
  end

  defp get_rows(repo, query, cursor_field, cursor, max_rows) do
    import Ecto.Query

    query
    |> order_by([o], asc: ^cursor_field)
    |> then(fn query ->
      if is_nil(cursor) do
        query
      else
        query |> where([r], field(r, ^cursor_field) > ^cursor)
      end
    end)
    |> limit(^max_rows)
    |> repo.all()
  end

  defp get_last_row_cursor(rows, cursor_field) do
    rows |> List.last() |> Map.fetch!(cursor_field)
  end
end
