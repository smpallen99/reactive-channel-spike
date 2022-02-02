defmodule ReactiveSocketWeb.RoomChannel do
  use ReactiveSocketWeb, :channel
  use ReactiveSocket.Reactive.Channel

  alias ReactiveSocket.Post

  require Logger

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, init_reactive(socket)}
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
    {:noreply, reactive(socket, Post.get_topic(), :post, {Post, :list, []})}
  end

  @impl true
  def_reactive_info()

  def handle_info(:after_join, socket) do
    Logger.info("after join")

    {:noreply, socket}
  end

  def handle_info(message, socket) do
    Logger.warn("invalid message: #{inspect(message)}")
    {:noreply, socket}
  end

  def render_post(posts) when is_list(posts), do: Enum.map(posts, &render_post/1)
  def render_post(post), do: Map.take(post, ~w(id title description)a)

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
