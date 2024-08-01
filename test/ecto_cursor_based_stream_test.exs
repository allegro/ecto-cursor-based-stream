defmodule EctoCursorBasedStreamTest do
  use TestApp.RepoCase

  describe "cursor_based_stream/2" do
    setup do
      rows = [
        Repo.insert!(%User{email: "1@test.com"}),
        Repo.insert!(%User{email: "2@test.com"}),
        Repo.insert!(%User{email: "3@test.com"})
      ]

      %{rows: rows}
    end

    test "if rows total count is smaller than :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_based_stream(max_rows: 50) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if rows total count is equal to the :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_based_stream(max_rows: 3) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if rows total count is larger than the :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_based_stream(max_rows: 2) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if :cursor_field option is given, iterates rows over that field", %{rows: rows} do
      result =
        User
        |> Repo.cursor_based_stream(max_rows: 2, cursor_field: :email)
        |> Enum.to_list()

      assert result == rows
    end

    test "if :after_cursor option is given, skips any rows with value not greater than it",
         %{
           rows: rows
         } do
      result =
        User
        |> Repo.cursor_based_stream(
          max_rows: 2,
          cursor_field: :email,
          after_cursor: "1@test.com"
        )
        |> Enum.to_list()

      assert result == rows |> Enum.slice(1, 2)
    end

    test "if :order option is given, changes order of result", %{rows: rows} do
      result =
        User
        |> Repo.cursor_based_stream(max_rows: 2, order: :asc)
        |> Enum.to_list()

      assert result == rows

      result =
        User
        |> Repo.cursor_based_stream(max_rows: 2, order: :desc)
        |> Enum.to_list()

      assert result == Enum.reverse(rows)
    end
  end
end
