defmodule ReactiveSocket.Post do
  # , topic: inspect(__MODULE__)
  use ReactiveSocket.Reactive.Model

  alias ReactiveSocket.PostServer, as: Server

  @derive {Jason.Encoder, only: ~w(id title description)a}
  defstruct [:id, :title, :description]

  def uuid, do: UUID.uuid4()

  def new(), do: %__MODULE__{}
  def new(opts), do: struct(new(), opts)

  def list, do: Server.list()

  def get(id), do: Server.get(id)

  def create(attrs) do
    attrs
    |> Map.put_new(:id, uuid())
    |> new()
    |> Server.insert()
    |> notify_subscribers(:create)
  end

  def update(schema, attrs) do
    Server.update(schema, attrs)
    |> notify_subscribers(:update)
  end

  def delete(schema) do
    schema
    |> Server.delete()
    |> notify_subscribers(:delete)
  end

  def seed(count \\ 10) do
    fun = fn id -> %{title: "Title #{id}", description: "description #{id}"} end
    Enum.map(1..count, &(create(fun.(&1)) |> elem(1)))
  end
end
