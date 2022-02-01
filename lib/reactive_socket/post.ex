defmodule ReactiveSocket.Post do
  alias ReactiveSocket.PostServer, as: Server

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
  end

  def update(schema, attrs) do
    Server.update(schema, attrs)
  end

  def delete(schema) do
    schema
    |> Server.delete()
  end

  def seed(count \\ 10) do
    fun = fn id -> %{title: "Title #{id}", description: "description #{id}"} end
    Enum.map(1..count, &(create(fun.(&1)) |> elem(1)))
  end
end
