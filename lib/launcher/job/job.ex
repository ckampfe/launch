defmodule Argument do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :value
  end

  def changeset(argument, attrs) do
    argument
    |> cast(attrs, [
      :value
    ])
    |> validate_required([:value])
  end
end

defmodule Launcher.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "job" do
    field :label, :string
    field :program, :string
    field :run_at_load, :boolean
    # field :arguments, {:array, :string}
    embeds_many :arguments, Argument
    field :environment_variables, {:array, :string}
    field :working_directory, :string
    field :start_interval, :integer
    field :keepalive, :boolean
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :label,
      :program,
      :run_at_load,
      :environment_variables,
      :working_directory,
      :start_interval,
      :keepalive
    ])
    |> cast_embed(:arguments)
    |> validate_required([:label, :program])

    # |> validate_required([:username, :email, :phone_number])
    # |> validate_confirmation(:password)
    # |> validate_format(:username, ~r/^[a-zA-Z0-9_]*$/,
    #   message: "only letters, numbers, and underscores please"
    # )
    # |> validate_length(:username, max: 12)
    # |> validate_format(:email, ~r/.+@.+/, message: "must be a valid email address")
    # |> validate_format(:phone_number, @phone, message: "must be a valid number")
    # |> unique_constraint(:email)
  end
end
