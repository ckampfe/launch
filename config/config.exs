# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :launcher,
  user_launchagents_path: Path.join([System.user_home!(), "Library", "LaunchAgents"])

config :launcher,
  ecto_repos: [Launcher.Repo]

# Configures the endpoint
config :launcher, LauncherWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "s5EK++UYGGHzdiY8xJxZ9wy2smgJX61f3p5e+1otQtc2bTaey1sl/jGQ2csBBEdw",
  render_errors: [view: LauncherWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Launcher.PubSub,
  live_view: [signing_salt: "BC/lISWI"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
