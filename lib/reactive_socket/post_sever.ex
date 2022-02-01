defmodule ReactiveSocket.PostServer do
  use GenServer

  @name __MODULE__

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: @name)

  def status, do: GenServer.call(@name, :status)

  def list, do: GenServer.call(@name, :list)
  def get(id), do: GenServer.call(@name, {:get, id})
  def insert(params), do: GenServer.call(@name, {:insert, params})
  def update(post, params), do: GenServer.call(@name, {:update, post, params})
  def delete(post), do: GenServer.call(@name, {:delete, post})

  def init(_) do
    {:ok, []}
  end

  def handle_call(:status, _, state), do: {:reply, state, state}

  def handle_call(:list, _, state), do: {:reply, state, state}

  def handle_call({:update, post, attrs}, _, posts) do
    do_update(posts, post, attrs)
  end

  def handle_call({:insert, attrs}, _, posts) do
    {post, posts} = do_insert(posts, attrs)
    {:reply, {:ok, post}, posts}
  end

  def handle_call({:get, id}, _, posts) do
    {:reply, do_get(posts, id), posts}
  end

  def handle_call({:delete, post}, _, posts) do
    {:reply, {:ok, post}, do_delete(posts, post)}
  end

  defp do_get(posts, id), do: Enum.find(posts, &(&1.id == id))
  defp do_insert(posts, post), do: {post, posts ++ [post]}
  defp do_delete(posts, %{id: id}), do: do_delete(posts, id)
  defp do_delete(posts, id), do: Enum.reject(posts, &(&1.id == id))

  defp do_update(posts, post, attrs) do
    if post = do_get(posts, post.id) do
      post = struct(post, Map.delete(attrs, :__struct__))

      posts =
        List.foldr(posts, [], fn i, acc ->
          if i.id == post.id, do: [post | acc], else: [i | acc]
        end)

      {:reply, {:ok, post}, posts}
    else
      {:reply, {:error, "invalid"}, posts}
    end
  end
end
