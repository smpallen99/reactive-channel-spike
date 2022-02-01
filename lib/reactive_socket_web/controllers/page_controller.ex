defmodule ReactiveSocketWeb.PageController do
  use ReactiveSocketWeb, :controller

  alias ReactiveSocket.Post

  def index(conn, _params) do
    render(conn, "index.html", posts: Post.list())
  end

  def list(conn, _) do
    render(conn, "list.html", posts: Post.list())
  end
end
