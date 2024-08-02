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
      |> MyRepo.cursor_based_stream(max_rows: 100)
      |> Stream.each(...)
      |> Stream.run()
  """
  import Ecto.Query

  @type cursor_based_stream_opts :: [
          {:max_rows, integer()}
          | {:after_cursor, String.t() | integer()}
          | {:cursor_field, atom()}
          | {:order, :asc | :desc}
        ]

  @doc """
  Return a lazy enumerable that emits all entries from the data store
  matching the given query.

  In contrast to `Ecto.Repo.stream/2`,
  this will not use database mechanisms (e.g. database transactions) to stream the rows.

  It does so by sorting all the rows by `options[:cursor_field]`
  and iterating over them in chunks of size `options[:max_rows]`.

  ## Options

  * `:cursor_field` - the field or list of fields by which all rows should be iterated.

    **This field must have unique values. (Otherwise, some rows may get skipped.)**

    For performance reasons, we recommend that you have an index on that field. Defaults to `:id`.

  * `:after_cursor` - the value of the `:cursor_field` that results start. When `:cursor_field` is a list
    then`:after_cursor` must be a map where keys are cursor fields.

    Useful when you want to continue streaming from a certain point.
    Any rows with value equal or smaller than this value will not be included.

    Defaults to `nil`. (All rows will be included.)

  * `:max_rows` - The number of rows to load from the database as we stream.

    Defaults to 500.

  * `:order` - Order of results, `:asc` or `:desc`

    Defaults to `:asc`.

  ## Examples

      MyUser
      |> MyRepo.cursor_based_stream(max_rows: 1000)
      |> Stream.each(...)
      |> Stream.run()

      # change order
      MyUser
      |> MyRepo.cursor_based_stream(order: :desc)
      |> Stream.each(...)
      |> Stream.run()

      # change cursor field and set starting cursor
      MyUser
      |> MyRepo.cursor_based_stream(cursor_field: :email, after_cursor: "foo@bar.com")
      |> Stream.each(...)
      |> Stream.run()

      # with multiple fields
      MyUser
      |> MyRepo.cursor_based_stream(cursor_field: [:email, :date_of_birth], after_cursor: %{email: "foo@bar.com"})
      |> Stream.each(...)
      |> Stream.run()

      # select custom fields
      # remember to add `cursor_field`!
      MyUser
      |> select([u], map(u, [:id, ...])
      |> MyRepo.cursor_based_stream()
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
  @spec call(Ecto.Repo.t(), Ecto.Queryable.t(), cursor_based_stream_opts) :: Enumerable.t()
  def call(repo, queryable, options \\ []) do
    %{after_cursor: after_cursor, cursor_fields: cursor_fields} = options = parse_options(options)

    Stream.unfold(after_cursor, fn cursor ->
      case get_rows(repo, queryable, cursor, options) do
        [] ->
          nil

        rows ->
          next_cursor = get_last_row_cursor(rows, cursor_fields)
          {rows, next_cursor}
      end
    end)
    |> Stream.flat_map(& &1)
  end

  defp parse_options(options) do
    max_rows = Keyword.get(options, :max_rows, 500)
    after_cursor = Keyword.get(options, :after_cursor, nil)
    cursor_field = Keyword.get(options, :cursor_field, :id)
    order = Keyword.get(options, :order, :asc)

    cursor_fields = validate_cursor_fields(cursor_field)

    %{
      max_rows: max_rows,
      cursor_fields: cursor_fields,
      after_cursor: validate_initial_cursor(cursor_fields, after_cursor),
      order: order
    }
  end

  defp validate_cursor_fields(value) do
    cursor_fields = List.wrap(value)

    if Enum.all?(cursor_fields, &is_atom/1) do
      cursor_fields
    else
      raise ArgumentError,
            "EctoCursorBasedStream expected `cursor_field` to be an atom or list of atoms, got: #{inspect(value)}."
    end
  end

  defp validate_initial_cursor(_, nil) do
    nil
  end

  defp validate_initial_cursor(cursor_fields, %{} = after_cursor) do
    {after_cursor, rest} = Map.split(after_cursor, cursor_fields)

    if map_size(rest) == 0 do
      after_cursor
    else
      raise ArgumentError,
            "EctoCursorBasedStream expected `after_cursor` to be a map with fields #{inspect(cursor_fields)}, got: #{inspect(rest)}."
    end
  end

  defp validate_initial_cursor([cursor_field], after_cursor) when not is_list(after_cursor) do
    %{cursor_field => after_cursor}
  end

  defp validate_initial_cursor(cursor_fields, after_cursor) do
    raise ArgumentError,
          "EctoCursorBasedStream expected `after_cursor` to be a map with fields #{inspect(cursor_fields)}, got: #{inspect(after_cursor)}."
  end

  defp get_rows(repo, query, cursor, options) do
    %{cursor_fields: cursor_fields, order: order, max_rows: max_rows} = options
    order_by = Enum.map(cursor_fields, fn cursor_field -> {order, cursor_field} end)

    query
    |> order_by([o], ^order_by)
    |> then(fn query ->
      apply_cursor(query, cursor_fields, cursor, order)
    end)
    |> limit(^max_rows)
    |> repo.all()
  end

  defp apply_cursor(query, _cursor_fields, nil, _order) do
    query
  end

  defp apply_cursor(query, cursor_fields, cursor, order) do
    Enum.reduce(cursor_fields, query, fn cursor_field, query ->
      cursor = Map.get(cursor, cursor_field)
      apply_cursor_field(query, cursor_field, cursor, order)
    end)
  end

  defp apply_cursor_field(query, _cursor_field, nil, _order) do
    query
  end

  defp apply_cursor_field(query, cursor_field, cursor, :desc) do
    where(query, [r], field(r, ^cursor_field) < ^cursor)
  end

  defp apply_cursor_field(query, cursor_field, cursor, _) do
    where(query, [r], field(r, ^cursor_field) > ^cursor)
  end

  defp get_last_row_cursor(rows, cursor_fields) do
    last_row = List.last(rows)

    unless is_map(last_row) do
      select = Enum.map_join(cursor_fields, ", ", &inspect/1)

      raise RuntimeError,
            "EctoCursorBasedStream query must return a map with cursor field. If you are using custom `select` ensure that all cursor fields are returned as a map, e.g. `select([s], map(s, [#{select}]))`."
    end

    Map.new(cursor_fields, fn cursor_field ->
      case Map.fetch(last_row, cursor_field) do
        {:ok, value} ->
          {cursor_field, value}

        :error ->
          raise ArgumentError,
                "EctoCursorBasedStream query did not return cursor field #{inspect(cursor_field)}. If you are using custom `select` ensure that all cursor fields are returned as a map, e.g. `select([s], map(s, [#{inspect(cursor_field)}, ...]))`."
      end
    end)
  end
end
