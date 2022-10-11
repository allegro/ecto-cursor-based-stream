Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:ecto_sql)

{:ok, _} = TestApp.Repo.start_link()

ExUnit.start()
