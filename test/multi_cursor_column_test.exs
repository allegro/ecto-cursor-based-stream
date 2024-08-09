defmodule MultiCursorColumnTest do
  use TestApp.RepoCase

  describe "multi column cursor" do
    setup do
      data =
        for x <- 1..5, y <- 1..5, z <- 1..5 do
          %{id_1: x, id_2: y, id_3: z}
        end

      Repo.insert_all(MultiCursor, data)
      :ok
    end

    test "iterates over all values" do
      for order <- [:asc, :desc] do
        result =
          MultiCursor
          |> where([c], c.id_1 == 1)
          |> Repo.cursor_stream(
            cursor_field: [:id_2, :id_3],
            max_rows: :rand.uniform(10),
            order: order
          )
          |> Enum.count()

        assert result == 25

        result =
          MultiCursor
          |> Repo.cursor_stream(
            cursor_field: [:id_1, :id_2, :id_3],
            max_rows: :rand.uniform(10),
            order: order
          )
          |> Enum.count()

        assert result == 125
      end
    end

    test ":after_cursor on multiple cursor fields with initial cursor ascending" do
      result =
        MultiCursor
        |> Repo.cursor_stream(
          cursor_field: [:id_1, :id_2, :id_3],
          after_cursor: %{id_1: 2, id_2: 3},
          max_rows: 20
        )
        |> Enum.to_list()

      assert length(result) == 3 * 25 + 2 * 5
      assert %{id_1: 2, id_2: 4, id_3: 1} = hd(result)
      assert %{id_1: 5, id_2: 5, id_3: 5} = List.last(result)

      result =
        MultiCursor
        |> Repo.cursor_stream(
          cursor_field: [:id_1, :id_2, :id_3],
          after_cursor: %{id_1: 2, id_2: 3, id_3: 4},
          max_rows: 20
        )
        |> Enum.to_list()

      assert length(result) == 3 * 25 + 2 * 5 + 1
      assert %{id_1: 2, id_2: 3, id_3: 5} = hd(result)
      assert %{id_1: 5, id_2: 5, id_3: 5} = List.last(result)
    end

    test ":after_cursor on multiple cursor fields with initial cursor descending" do
      result =
        MultiCursor
        |> Repo.cursor_stream(
          cursor_field: [:id_1, :id_2, :id_3],
          after_cursor: %{id_1: 2, id_2: 3},
          max_rows: 20,
          order: :desc
        )
        |> Enum.to_list()

      assert length(result) == 1 * 25 + 2 * 5
      assert %{id_1: 2, id_2: 2, id_3: 5} = hd(result)
      assert %{id_1: 1, id_2: 1, id_3: 1} = List.last(result)

      result =
        MultiCursor
        |> Repo.cursor_stream(
          cursor_field: [:id_1, :id_2, :id_3],
          after_cursor: %{id_1: 2, id_2: 3, id_3: 4},
          max_rows: 20,
          order: :desc
        )
        |> Enum.to_list()

      assert length(result) == 1 * 25 + 2 * 5 + 3
      assert %{id_1: 2, id_2: 3, id_3: 3} = hd(result)
      assert %{id_1: 1, id_2: 1, id_3: 1} = List.last(result)
    end

    test "multiple cursor fields with custom order" do
      result =
        MultiCursor
        |> Repo.cursor_stream(
          cursor_field: [id_1: :asc, id_2: :desc, id_3: :asc],
          after_cursor: %{id_1: 2, id_2: 3, id_3: 2},
          max_rows: 20
        )
        |> Enum.to_list()

      assert length(result) == 3 * 25 + 2 * 5 + 3
      assert %{id_1: 2, id_2: 3, id_3: 3} = hd(result)
      assert %{id_1: 5, id_2: 1, id_3: 5} = List.last(result)
    end

    test "multiple cursor fields query" do
      {items, next_cursor} =
        MultiCursor
        |> Repo.cursor_query(
          cursor_field: [id_1: :asc, id_2: :desc, id_3: :asc],
          after_cursor: %{id_1: 2, id_2: 3, id_3: 2},
          max_rows: 20
        )

      assert length(items) == 20
      assert %{id_1: 3, id_2: 4, id_3: 2} = next_cursor
    end
  end
end
