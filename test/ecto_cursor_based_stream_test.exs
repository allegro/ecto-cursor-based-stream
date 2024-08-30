defmodule CursornatorTest do
  use TestApp.RepoCase

  describe "cursor_stream/2" do
    setup do
      rows = [
        Repo.insert!(%User{
          email: "1@test.com",
          country_of_birth: "POL",
          date_of_birth: ~U[1990-01-01 00:00:00.000000Z]
        }),
        Repo.insert!(%User{
          email: "2@test.com",
          country_of_birth: "POL",
          date_of_birth: ~U[1991-02-02 00:00:00.000000Z]
        }),
        Repo.insert!(%User{
          email: "3@test.com",
          country_of_birth: "GER",
          date_of_birth: ~U[1992-03-03 00:00:00.000000Z]
        }),
        Repo.insert!(%User{
          email: "4@test.com",
          country_of_birth: "GER",
          date_of_birth: ~U[1993-04-04 00:00:00.000000Z]
        }),
        Repo.insert!(%User{
          email: "5@test.com",
          country_of_birth: "GBR",
          date_of_birth: ~U[1994-05-05 00:00:00.000000Z]
        })
      ]

      %{rows: rows}
    end

    test "if rows total count is smaller than :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_stream(max_rows: 50) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if rows total count is equal to the :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_stream(max_rows: 3) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if rows total count is larger than the :max_rows option, streams all the rows", %{
      rows: rows
    } do
      result = User |> Repo.cursor_stream(max_rows: 2) |> Enum.to_list()

      assert result == rows |> Enum.sort_by(& &1.id)
    end

    test "if :cursor_field option is given, iterates rows over that field", %{rows: rows} do
      result =
        User
        |> Repo.cursor_stream(max_rows: 2, cursor_field: :email)
        |> Enum.to_list()

      assert result == rows
    end

    test "if :cursor_field is a list of fields, iterates rows over all fields", %{rows: rows} do
      result =
        User
        |> Repo.cursor_stream(cursor_field: [:country_of_birth, :date_of_birth])
        |> Enum.to_list()

      assert result == Enum.sort_by(rows, &{&1.country_of_birth, &1.date_of_birth})
    end

    test "if :after_cursor option is given, skips any rows with value not greater than it",
         %{
           rows: rows
         } do
      result =
        User
        |> Repo.cursor_stream(
          max_rows: 2,
          cursor_field: :email,
          after_cursor: "1@test.com"
        )
        |> Enum.to_list()

      assert result == rows |> Enum.slice(1, 4)
    end

    test "if :order option is given, changes order of result", %{rows: rows} do
      result =
        User
        |> Repo.cursor_stream(max_rows: 2, order: :asc)
        |> Enum.to_list()

      assert result == rows

      result =
        User
        |> Repo.cursor_stream(max_rows: 2, order: :desc)
        |> Enum.to_list()

      assert result == Enum.reverse(rows)
    end

    test "sorting on multiple cursor fields", %{rows: rows} do
      result =
        User
        |> Repo.cursor_stream(
          cursor_field: [:country_of_birth, :date_of_birth],
          order: :asc
        )
        |> Enum.to_list()

      assert result == Enum.sort_by(rows, &{&1.country_of_birth, &1.date_of_birth})

      result =
        User
        |> Repo.cursor_stream(
          cursor_field: [:country_of_birth, :date_of_birth],
          order: :desc
        )
        |> Enum.to_list()

      assert result ==
               Enum.sort_by(rows, &{&1.country_of_birth, &1.date_of_birth}) |> Enum.reverse()
    end

    defmodule RepoStub do
      use Cursornator

      def all(query, options) do
        send(self(), {__MODULE__, query, options})
        []
      end
    end

    test "if repo opts are given they are passed to Repo.all/2" do
      User
      |> RepoStub.cursor_stream(prefix: "public", timeout: 10_000, log: false)
      |> Enum.to_list()

      assert_receive {RepoStub, _query, options}

      assert options == [prefix: "public", timeout: 10_000, log: false]
    end

    defmodule ParallelRepoStub do
      use Cursornator

      def all(_query, _options) do
        :timer.sleep(100)

        [%User{id: System.monotonic_time()}]
      end
    end

    test "if :parellel option is given, fetches data in parallel" do
      [not_parallel_duration, parallel_duration] =
        for parallel? <- [false, true] do
          :timer.tc(fn ->
            ParallelRepoStub.cursor_stream(User, parallel: parallel?)
            |> Stream.each(fn _ -> :timer.sleep(100) end)
            |> Enum.take(5)
          end)
          |> elem(0)
        end

      # assert parallel version is roughly 2 times faster
      difference = parallel_duration / not_parallel_duration * 100
      assert difference <= 60
      assert difference >= 50
    end
  end

  describe "validations" do
    setup do
      rows = [
        Repo.insert!(%User{
          email: "1@test.com",
          country_of_birth: "POL",
          date_of_birth: ~U[1990-01-01 00:00:00.000000Z]
        })
      ]

      %{rows: rows}
    end

    test ":cursor_field must be an atom or list of atoms" do
      assert_raise ArgumentError,
                   "Cursornator expected `cursor_field` to be an atom or list of atoms or list of tuple {atom, :asc|:desc}, got: %{}.",
                   fn ->
                     User
                     |> Repo.cursor_stream(cursor_field: %{})
                     |> Enum.to_list()
                   end

      assert_raise ArgumentError,
                   "Cursornator expected `cursor_field` to be an atom or list of atoms or list of tuple {atom, :asc|:desc}, got: \"email\".",
                   fn ->
                     User
                     |> Repo.cursor_stream(cursor_field: "email")
                     |> Enum.to_list()
                   end

      assert_raise ArgumentError,
                   "Cursornator expected `cursor_field` to be an atom or list of atoms or list of tuple {atom, :asc|:desc}, got: [:id, \"email\"].",
                   fn ->
                     User
                     |> Repo.cursor_stream(cursor_field: [:id, "email"])
                     |> Enum.to_list()
                   end
    end

    test ":after_cursor must contain fields from `cursor_field`" do
      assert_raise ArgumentError,
                   "Cursornator expected `after_cursor` to be a map with fields [:id, :email], got: \"10\".",
                   fn ->
                     User
                     |> Repo.cursor_stream(cursor_field: [:id, :email], after_cursor: "10")
                     |> Enum.to_list()
                   end

      assert_raise ArgumentError,
                   "Cursornator expected `after_cursor` to be a map with fields [:id, :email], got: %{emial: \"foo@bar.com\"}.",
                   fn ->
                     User
                     |> Repo.cursor_stream(
                       cursor_field: [:id, :email],
                       after_cursor: %{emial: "foo@bar.com"}
                     )
                     |> Enum.to_list()
                   end
    end

    test "query must `select` cursor fields" do
      assert_raise RuntimeError,
                   "Cursornator query must return a map with cursor field. If you are using custom `select` ensure that all cursor fields are returned as a map, e.g. `select([s], map(s, [:id]))`.",
                   fn ->
                     User
                     |> select([u], u.id)
                     |> Repo.cursor_stream(cursor_field: :id)
                     |> Enum.to_list()
                   end

      assert_raise RuntimeError,
                   "Cursornator query did not return cursor field :id. If you are using custom `select` ensure that all cursor fields are returned as a map, e.g. `select([s], map(s, [:id, ...]))`.",
                   fn ->
                     User
                     |> select([u], %{email: u.email})
                     |> Repo.cursor_stream(cursor_field: :id)
                     |> Enum.to_list()
                   end

      assert_raise RuntimeError,
                   "Cursornator query did not return cursor field :id. If you are using custom `select` ensure that all cursor fields are returned as a map, e.g. `select([s], map(s, [:id, ...]))`.",
                   fn ->
                     User
                     |> select([u], %{email: u.email})
                     |> Repo.cursor_stream(cursor_field: [:email, :id])
                     |> Enum.to_list()
                   end
    end
  end
end
