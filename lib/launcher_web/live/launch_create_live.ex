defmodule LauncherWeb.LaunchCreateLive do
  use LauncherWeb, :live_view
  alias Launcher.{Job, Jobs}
  import XmlBuilder

  @user_launchagents_path Application.fetch_env!(:launcher, :user_launchagents_path)

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      Jobs.change_job(%Job{}, %{
        label: "com.yourprogram.yourid",
        program: "/path/to/your/program.sh",
        arguments: [
          %{value: "arg1"},
          %{value: "arg2"}
        ],
        environment_variables: [
          %{key: "PORT", value: "5000"}
        ]
      })

    socket =
      socket
      |> assign(
        xml_string: "",
        changeset: changeset,
        run_at_load: false,
        keepalive: false
      )
      |> render_xml()

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"job" => attrs}, socket) do
    changeset =
      %Job{}
      |> Launcher.Jobs.change_job(attrs)
      # this has to be here for errors to render
      |> Map.put(:action, :insert)

    if changeset.valid? do
      socket =
        socket
        |> assign(changeset: changeset)
        |> render_xml()

      {:noreply, socket}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"job" => attrs}, socket) do
    changeset =
      %Job{}
      |> Launcher.Jobs.change_job(attrs)
      |> Map.put(:action, :insert)

    job_write_path = Path.join(@user_launchagents_path, "#{changeset.changes.label}.plist")

    if changeset.valid? do
      socket =
        socket
        |> assign(changeset: changeset)
        |> render_xml()
        |> put_flash(
          :info,
          "wrote job definition to #{job_write_path}"
        )

      File.write!(job_write_path, socket.assigns.xml_string)

      {:noreply, socket}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("add-arg", _params, socket) do
    arg = %Argument{value: ""}

    arguments = Map.get(socket.assigns.changeset.changes, :arguments, []) ++ [arg]

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(
        :arguments,
        arguments
      )

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("remove-arg", %{"id" => id} = _params, socket) do
    [idx | _] =
      Regex.run(~r/\d+/, id)
      |> Enum.map(fn s ->
        {i, _} = Integer.parse(s)
        i
      end)

    arguments =
      socket.assigns.changeset.changes.arguments
      |> List.delete_at(idx)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(
        :arguments,
        arguments
      )

    socket =
      assign(socket, changeset: changeset)
      |> render_xml()

    {:noreply, socket}
  end

  def handle_event("add-environment-variable", _params, socket) do
    var = %EnvironmentVariable{key: "", value: ""}

    environment_variables =
      Map.get(socket.assigns.changeset.changes, :environment_variables, []) ++ [var]

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(
        :environment_variables,
        environment_variables
      )

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("remove-environment-variable", %{"id" => id} = _params, socket) do
    [idx | _] =
      Regex.run(~r/\d+/, id)
      |> Enum.map(fn s ->
        {i, _} = Integer.parse(s)
        i
      end)

    environment_variables =
      socket.assigns.changeset.changes.environment_variables
      |> List.delete_at(idx)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(
        :environment_variables,
        environment_variables
      )

    socket =
      assign(socket, changeset: changeset)
      |> render_xml()

    {:noreply, socket}
  end

  def render_xml(socket) do
    elements = changes_to_elements(socket.assigns.changeset)

    xml_string =
      document([
        doctype("plist",
          public: [
            "-//Apple//DTD PLIST 1.0//EN",
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd"
          ]
        ),
        element(:plist, %{version: "1.0"}, [
          element(
            :dict,
            elements
          )
        ])
      ])
      |> XmlBuilder.generate()

    assign(socket, xml_string: xml_string)
  end

  def changes_to_elements(changeset) do
    label = [
      element(:key, "Label"),
      element(:string, changeset.changes.label)
    ]

    program_args =
      if Enum.empty?(Map.get(changeset.changes, :arguments, [])) do
        [element(:key, "Program"), element(:string, changeset.changes.program)]
      else
        [
          element(:key, "ProgramArguments"),
          element(
            :array,
            [
              element(:string, changeset.changes.program),
              Enum.map(
                changeset.changes.arguments,
                fn argument ->
                  element(:string, argument.changes.value)
                end
              )
            ]
          )
        ]
      end

    run_at_load =
      if changeset.changes[:run_at_load] do
        [element(:key, "RunAtLoad"), element(changeset.changes.run_at_load)]
      else
        []
      end

    keepalive =
      if changeset.changes[:keepalive] do
        [element(:key, "KeepAlive"), element(changeset.changes.keepalive)]
      else
        []
      end

    standard_in_path =
      if changeset.changes[:standard_in_path] do
        [element(:key, "StandardInPath"), element(:string, changeset.changes.standard_in_path)]
      else
        []
      end

    standard_out_path =
      if changeset.changes[:standard_out_path] do
        [element(:key, "StandardOutPath"), element(:string, changeset.changes.standard_out_path)]
      else
        []
      end

    standard_error_path =
      if changeset.changes[:standard_error_path] do
        [
          element(:key, "StandardErrorPath"),
          element(:string, changeset.changes.standard_error_path)
        ]
      else
        []
      end

    environment_variables =
      if vars = Map.get(changeset.changes, :environment_variables) do
        [
          element(:key, "EnvironmentVariables"),
          element(
            :dict,
            Enum.flat_map(vars, fn %{changes: %{key: key, value: value}} ->
              [
                element(:key, key),
                element(:string, value)
              ]
            end)
          )
        ]
      else
        []
      end

    label ++
      program_args ++
      run_at_load ++
      keepalive ++
      standard_in_path ++
      standard_out_path ++
      standard_error_path ++
      environment_variables
  end
end
