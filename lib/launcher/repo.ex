defmodule Launcher.Repo do
  use Ecto.Repo,
    otp_app: :launcher,
    adapter: Ecto.Adapters.Postgres
end
