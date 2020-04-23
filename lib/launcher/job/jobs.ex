defmodule Launcher.Jobs do
  alias Launcher.Job

  def change_job(job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end
end
