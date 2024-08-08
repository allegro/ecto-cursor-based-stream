defmodule TestApp.MultiCursor do
  use Ecto.Schema

  @primary_key false
  schema "multi_cursor" do
    field(:id_1, :integer)
    field(:id_2, :integer)
    field(:id_3, :integer)
  end
end
