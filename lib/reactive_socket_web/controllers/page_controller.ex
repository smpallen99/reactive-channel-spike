defmodule ReactiveSocketWeb.PageController do
  use ReactiveSocketWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
