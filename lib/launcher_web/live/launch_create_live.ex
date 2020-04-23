defmodule LauncherWeb.LaunchCreateLive do
  use LauncherWeb, :live_view
  alias Launcher.{Job, Jobs}
  import XmlBuilder

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      Jobs.change_job(%Job{}, %{
        label: "com.yourprogram.yourid",
        program: "/path/to/your/program.sh",
        arguments: [
          %{value: "arg1"},
          %{value: "arg2"}
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
  def handle_event("validate", %{"job" => params}, socket) do
    changeset =
      %Job{}
      |> Launcher.Jobs.change_job(params)
      |> IO.inspect(label: "CS")

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

    socket = assign(socket, changeset: changeset)

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
        element(:plist, [
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
      if Enum.empty?(changeset.changes.arguments) do
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

    label ++
      program_args ++
      run_at_load ++
      keepalive
  end
end
