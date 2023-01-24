defmodule TestApp.RepoCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias TestApp.Repo
      alias TestApp.User
    end
  end

  setup tags do
    :ok = Sandbox.checkout(TestApp.Repo)

    unless tags[:async] do
      Sandbox.mode(TestApp.Repo, {:shared, self()})
    end

    :ok
  end
end
