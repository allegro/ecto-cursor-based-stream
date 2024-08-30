defmodule Cursornator.TaskSynchronous do
  @moduledoc false

  def async(fun) do
    result = fun.()

    struct(Task, %{
      owner: self(),
      pid: self(),
      ref: result,
      mfa: {:erlang, :apply, [fun, []]}
    })
  end

  def await(%Task{ref: result}, _timeout \\ 5000) do
    result
  end
end
