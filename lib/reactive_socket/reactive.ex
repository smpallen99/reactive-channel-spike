defmodule ReactiveSocket.Reactive do
  defmodule Model do
    defmacro __using__(opts \\ []) do
      quote do
        opts = unquote(opts)
        IO.puts("using :model #{inspect(opts)}")
        @topic opts[:topic] || inspect(__MODULE__)
        def get_topic, do: IO.inspect(@topic, label: "get_topic")

        def subscribe do
          Phoenix.PubSub.subscribe(ReactiveSocket.PubSub, @topic)
        end

        def notify_subscribers({:ok, result}, event) do
          IO.inspect(@topic, label: "notify on topic")

          Phoenix.PubSub.broadcast(
            ReactiveSocket.PubSub,
            @topic,
            {:reactive, {__MODULE__, event, result}}
          )

          {:ok, result}
        end

        def notify_subscribers({:error, changeset}, _) do
          {:error, changeset}
        end

        defoverridable(subscribe: 0, notify_subscribers: 2)
      end
    end
  end

  defmodule Channel do
    defmacro def_reactive_info do
      quote do
        def handle_info({:reactive, message}, socket) do
          handle_reactive_message(message, socket)
        end
      end
    end

    defmacro __using__(opts \\ []) do
      quote do
        import unquote(__MODULE__), only: [def_reactive_info: 0]
        require Logger
        opts = unquote(opts)

        def init_reactive(socket) do
          assign(socket, :reactive, %{subscriptions: %{}})
        end

        defp handle_reactive_message(
               {mod, event, resp},
               %{assigns: %{reactive: reactive}} = socket
             ) do
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

        def reactive(socket, topic, key, mfa), do: reactive(socket, topic, key, mfa, [])

        def reactive(socket, topic, key, mfa, opts) do
          IO.inspect(topic, label: "calling reactive with topic")

          {mod, fun, args} =
            if tuple_size(mfa) == 3, do: mfa, else: {elem(mfa, 0), nil, elem(mfa, 1)}

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

        defoverridable(reactive: 4, reactive: 5, update_schema: 4, handle_reactive_message: 2)
      end
    end
  end
end
