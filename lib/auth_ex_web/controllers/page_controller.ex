
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
        |>redirect(to: "/")
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

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    Auth.authenticate_user(email, password)
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

  def room_form(conn, _params) do
    render(conn, "create_room.html")
  end

  def create_room(conn, _params) do
    current_user = Guardian.Plug.current_resource(conn)
    email = Map.get(current_user, :email)
    username = Map.get(current_user, :username)
    id = Map.get(current_user, :id)
    input_email = conn.params["search"]["for"]
    other_user = AuthEx.Repo.get_by(AuthEx.Auth.User, email: input_email)
    if other_user == nil do
      conn
      |> put_flash(:error, "User does not exists")
      |> redirect(to: "/room/lobby?user=#{username}")
    else
      other_user_id = Map.get(other_user, :id)
      room_name = "#{id}_#{other_user_id}"
      room_params = %{
        participant: [email, input_email],
        name: room_name
      }
    
      exists = Rooms.get_room?(room_name)
      IO.puts(exists)
    
      if exists do
        conn
        |> put_flash(:success, "Welcome back!")
        |> redirect(to: "/room/#{room_name}?user=#{username}")
      else
        IO.puts("creating new room")
        create_new_room(room_params)
        conn
        |> put_flash(:success, "Room created successfully")
        |> redirect(to: "/room/#{room_name}?user=#{username}")
      end
    end
  end

  defp create_new_room(room_params) do
    %Rooms{status: "active"}
    |> Rooms.changeset(room_params)
    |> Repo.insert()
  end
end
