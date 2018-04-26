
 defmodule AuthExWeb.PageController do
  use AuthExWeb, :controller
  alias AuthEx.Auth
  alias AuthEx.Auth.User
  alias AuthEx.Auth.Guardian
  alias AuthEx.Repo
  alias AuthEx.Rooms

  def index(conn, _params) do
    changeset = Auth.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)
    message = if maybe_user != nil do
      "Someone is logged in"
    else
      "No one is logged in"
    end

    if maybe_user != nil do
        conn
        |>redirect(to: "/login")
    else
        conn
        |> put_flash(:info, message)
        |> render("index.html", changeset: changeset, action: page_path(conn, :login), maybe_user: maybe_user)
    end
  end

  def new(conn, _params) do
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
        |>redirect(to: "/room/lobby?user=#{username}")
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
        |> redirect(to: "/")
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
    |> redirect(to: "/room/lobby?user=#{username}")
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: page_path(conn, :login))
  end

  def secret(conn, _params) do
    render(conn, "secret.html")
  end

  def room(conn, %{"room_id" => room_id}) do
    # render(conn, "room.html")
    conn |> render_room(room_id)
  end

  def room(conn, _params) do
    # render(conn, "room.html")
    conn |> render_room("lobby")
  end

  defp render_room(conn, room_id) do
    conn |> render("room.html", room_id: room_id)
  end

  def create_room(conn, params) do
    username = params["username"]
    room_name = "random"
    room_params = %{
      participant: [],
      name: room_name
    }
    
    exists = Rooms.get_room?(room_name)
    IO.puts(exists)
    if exists do
      conn
      |> put_flash(:success, "Welcome back!")
      |> redirect(to: "/room/#{room_name}")
    else
      IO.puts("creating new room")
      create_new_room(room_params)
      conn
      |> put_flash(:success, "Room created successfully")
      |> redirect(to: "/room/#{room_name}")
    end
  end

  defp create_new_room(room_params) do
    %Rooms{}
    |> Rooms.changeset(room_params)
    |> Repo.insert()
  end
end
