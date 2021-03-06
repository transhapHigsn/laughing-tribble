defmodule AuthExWeb.Router do
  use AuthExWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug AuthEx.Auth.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

   # Maybe logged in scope
   scope "/", AuthExWeb do
    pipe_through [:browser, :auth]
    get "/", PageController, :index
    post "/", PageController, :login
    post "/logout", PageController, :logout
    get "/new", PageController, :new
    post "/create", PageController, :create
  end

  # Definitely logged in scope
  scope "/", AuthExWeb do
    pipe_through [:browser, :auth, :ensure_auth]
    get "/secret", PageController, :secret
    get "/room/:room_id", PageController, :room
    get "/new_room", PageController, :room_form
    post "/new_room", PageController, :create_room
    get "/rooms", PageController, :get_rooms
  end

  # Other scopes may use custom stacks.
  # scope "/api", AuthExWeb do
  #   pipe_through :api
  # end
end
