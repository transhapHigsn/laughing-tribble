# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :auth_ex,
  ecto_repos: [AuthEx.Repo]

# Configures the endpoint
config :auth_ex, AuthExWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7zw2f99I+YfvqKi19sHKwsNRxOu4twqdaeUYkv7T3cGxpGHA+TQfTuy4UTt3bnwW",
  render_errors: [view: AuthExWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AuthEx.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :auth_ex, AuthEx.Auth.Guardian,
  issuer: "auth_ex", 
  secret_key: "DMGk3p5SNrsfFI3pWlKXVPKrA2pLXB0vmWNJ2AQ5Ia5Po5OXtSwjR2hX6oZGpu0e"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
