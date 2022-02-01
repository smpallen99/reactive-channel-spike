defmodule ReactiveSocketWeb.RoomChannel do
  use ReactiveSocketWeb, :channel

  alias ReactiveSocket.Post

  require Logger

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, assign(socket, :reactive, %{subscriptions: %{}})}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("subscribe:post", payload, socket) do
    Logger.info("subscribe:post #{inspect(payload)}")
    socket = reactive(socket, Post.get_topic(), :post, {Post, :list, []})
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    Logger.info("after join")

    {:noreply, socket}
  end

  def handle_info({:reactive, message}, socket) do
    handle_reactive_message(message, socket)
  end

  def handle_info(message, socket) do
    Logger.warn("invalid message: #{inspect(message)}")
    {:noreply, socket}
  end

  defp handle_reactive_message({mod, event, resp}, %{assigns: %{reactive: reactive}} = socket) do
    IO.inspect(reactive, label: "reactive")

    if entry = reactive.subscriptions[mod] do
      Logger.info("found entry #{inspect(entry)}")
      push(socket, "change:#{event}", %{item: resp})
      {:noreply, update_schema(socket, event, entry, resp)}
    else
      Logger.warn(
        "received broadcast for invalid topic #{inspect([mod])}, #{inspect(event)}, #{inspect(Map.keys(reactive.subscriptions))}"
      )

      {:noreply, socket}
    end
  end

  defp update_schema(socket, :update, %{key: key}, item) do
    items =
      Enum.map(socket.assigns[key], fn i ->
        if item.id == i.id, do: item, else: i
      end)

    assign(socket, key, items)
  end

  defp update_schema(socket, :delete, %{key: key}, item) do
    items = Enum.reject(socket.assigns[key], &(&1.id == item.id))
    assign(socket, key, items)
  end

  defp update_schema(socket, :create, %{key: key}, item) do
    assign(socket, key, socket.assigns[key] ++ [item])
  end

  def render_post(posts) when is_list(posts), do: Enum.map(posts, &render_post/1)
  def render_post(post), do: Map.take(post, ~w(id title description)a)

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  def reactive(socket, topic, key, mfa, opts \\ []) do
    IO.inspect(topic, label: "calling reactive with topic")
    {mod, fun, args} = if tuple_size(mfa) == 3, do: mfa, else: {elem(mfa, 0), nil, elem(mfa, 1)}

    item = if fun, do: apply(mod, fun, args), else: args

    renderer = Keyword.get(opts, :renderer, String.to_existing_atom("render_#{key}"))
    item = apply(__MODULE__, renderer, [item])
    # push(socket, to_string(key), item)

    entry = %{
      topic: mod,
      events: opts[:events] || ~w(create update delete)a,
      key: key,
      opts: opts,
      update: opts[:update]
    }

    apply(mod, :subscribe, [])

    socket
    |> assign(key, item)
    |> put_subscription(mod, entry)
  end

  defp put_subscription(socket, topic, entry) do
    reactive = put_in(socket.assigns.reactive, [:subscriptions, topic], entry)
    assign(socket, :reactive, reactive)
  end
end

# 	defp handle_reactive_message({topic, :update, resp}, %{assigns: %{reactive: reactive}} = socket) do
# 	  # on update, we want convert schema to map, then filter by keys if provided
# 		# then find the item from assigns
# 		# diff the changes and broadcast only the changed keys
# 	   # data = reactive[topic]
# 		 # resp if data && event in data.events do
# 		  #  resp = if event == :update, Map.take(resp, data[:update] || Map.keys(resp)), else: Map.from_struct(resp)
# 	end
# end
# ```

# * how does client subscribe?

# ```elixir
# def handle_in("subscribe:posts", payload, socket) do
# 	socket = reactive(socket, :posts, payload["id"], {Post, :list_by, [[name: name]])
# 	if Map.get(payload, "reply", true) do
# 		{:reply, {:ok, %{id: payload["id", posts: socket.assigns.posts, success: true}, socket}
# 	else
# 	  {:noreply, socket}
#   end
# end
# ```

# #### Reactive API ideas

# * reactive(socket, :rooms, Room, :list_by, [[name: name]],opts)
#   * runs subscribe on the model
# 	* runs the following
# 	```
# 	def reactive(socket, key, mfa, args, opts \\ []) do
# 	  {mod, fun_or_default, args} = if tuple_size(mfa) == 3, do: mfa, else: {elem0, nil, elem2}
# 	  # we can probably run `apply(mod, :subscribe, Keyword.get(opts, :subscribe_opts, []))`

# 		item = if args, do: apply(mod, fun_or_default, args), else: fun_or_default
# 		# need to figure out how to render the item. perhaps an option, or imfer)
# 		# inter as apply(__MODULE__, String.to_existing_atom("render_#{key}), [args])
# 		push(socket, to_string(key), render(item))
# 		# the data we should leave in the channel assigns
# 		%{reactive: %{subscriptions: %{topic => %{topic: topic, events: opts[:events] || [:create, :update, :delete], key: key, opts: opts}}}

# 		socket
# 		|> assign(key, item)
# 		|> update(:reactive, &Map.update(&1, :keys, %{key => opts}, fn v -> Map.put(v, key, opts) end))
# 	end

# 	```
