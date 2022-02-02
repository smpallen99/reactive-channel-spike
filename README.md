# ReactiveSocket

## Goal

The following develop "Spike" is an attempt at some helpers to make a phoenix
channel "Reactive" for various "Models".

Aside from server support, a small Javascript library is also necessary. I have
not implemented a reusable library, so the js is hand coded for this demo.

The idea is to create a reusable pattern for adding reactive models to a Phoenix
channel.

This is an alternative to LiveView since its designed to work with a Vue or React
SPA to handle the front end.

Note: To avoid ecto and database setup, this sike simulates this with a simple
      GenServer to store the "table" in memory.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
