
 defmodule AuthExWeb.PageController do
  use AuthExWeb, :controller
  alias AuthEx.Auth
  alias AuthEx.Auth.User
  alias AuthEx.Auth.Guardian
  alias AuthEx.Repo

  def index(conn, _params) do
    changeset = Auth.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)
    message = if maybe_user != nil do
      "Someone is logged in"
    else
      "No one is logged in"
    end

    if maybe_user != nil do
        username = Map.get(maybe_user, :username)
        conn
        |>redirect(to: "/login")
    else
        conn
        |> put_flash(:info, message)
        |> render("index.html", changeset: changeset, action: page_path(conn, :login), maybe_user: maybe_user)
    end
  end

  def new(conn, _params) do
    # maybe_user = Guardian.Plug.current_resource(conn)
    # render conn, "signup.html", changeset: User.changeset(%User{}, %{})

    changeset = Auth.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)
    message = if maybe_user != nil do
      "Someone is logged in"
    else
      "No one is logged in"
    end

    if maybe_user != nil do
        username = Map.get(maybe_user, :username)
        conn
        |>redirect(to: "/room?user=#{username}")
    else
        conn
        |> put_flash(:info, message)
        |> render("signup.html", changeset: changeset, action: page_path(conn, :create), maybe_user: maybe_user)
    end
  end

  def create(conn, %{"user" => user_params}) do
    result=
      %User{}
      |> User.changeset(user_params)
      |> Repo.insert()

    case result do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Registration successful")
        |> redirect(to: "/login")
      {:error, changeset} ->
        render conn, "signup.html", changeset: changeset
    end
  end

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    Auth.authenticate_user(username, password)
    |> login_reply(conn)
  end

  defp login_reply({:error, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: "/")
  end

  defp login_reply({:ok, user}, conn) do
    username = Map.get(user, :username)
    conn
    |> put_flash(:success, "Welcome back!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: "/room?user=#{username}")
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: page_path(conn, :login))
  end

  def secret(conn, _params) do
    render(conn, "secret.html")
  end

  def room(conn, _params) do
      render(conn, "room.html")
  end
end
