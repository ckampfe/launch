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
    field :standard_in_path, :string, default: ""
    field :standard_out_path, :string, default: ""
    field :standard_error_path, :string, default: ""
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
      :keepalive,
      :standard_in_path,
      :standard_out_path,
      :standard_error_path
    ])
    |> cast_embed(:arguments)
    |> validate_required([:label, :program])
  end
end
