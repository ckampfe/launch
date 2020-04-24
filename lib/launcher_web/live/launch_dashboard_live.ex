defmodule LauncherWeb.LaunchDashboardLive do
  use LauncherWeb, :live_view
  alias Launcher.{Job, Jobs}
  import SweetXml

  @default_tick_interval :timer.seconds(5)
  @user_launchagents_path Application.fetch_env!(:launcher, :user_launchagents_path)

  @impl true
  def mount(_params, _session, socket) do
    timer =
      if connected?(socket) do
        Process.send(self(), :fs_poll_tick, [])
        :timer.send_interval(@default_tick_interval, self(), :fs_poll_tick)
      end

    socket =
      socket
      |> assign(
        timer: timer,
        launchd_files: [],
        changeset: Jobs.change_job(%Job{}),
        unfold_map: %{}
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle-fs-polling", %{}, socket) do
    if socket.assigns.timer do
      :timer.cancel(socket.assigns.timer)
      {:noreply, assign(socket, timer: nil)}
    else
      timer = :timer.send_interval(@default_tick_interval, self(), :fs_poll_tick)
      {:noreply, assign(socket, timer: timer)}
    end
  end

  @impl true
  def handle_event("inspect-file", %{"filename" => filename}, socket) do
    unfold_map = socket.assigns.unfold_map

    unfold_map =
      if Map.get(unfold_map, filename) do
        Map.delete(unfold_map, filename)
      else
        t = Task.async(fn -> File.read!(Path.join(@user_launchagents_path, filename)) end)
        Map.put(unfold_map, filename, Task.await(t))
      end

    socket = assign(socket, unfold_map: unfold_map)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:fs_poll_tick, socket) do
    {:noreply, put_launchd_files(socket)}
  end

  def put_launchd_files(socket) do
    case File.ls(@user_launchagents_path) do
      {:ok, files} ->
        {s, 0} = System.cmd("launchctl", ["list"])

        launchctl_list = String.split(s, "\n")

        files =
          files
          |> Enum.map(fn filename ->
            Task.async(fn ->
              {filename, File.read!(Path.join(@user_launchagents_path, filename))}
            end)
          end)
          |> Enum.map(fn t ->
            {filename, file} = Task.await(t)

            Task.async(fn ->
              {filename,
               SweetXml.xpath(file, ~x"//*[text() = 'Label']/following-sibling::node()/text()")
               |> to_string()}
            end)
          end)
          |> Enum.map(fn t ->
            {filename, job_label} = Task.await(t)

            Task.async(fn ->
              {filename,
               Enum.find(launchctl_list, fn entry ->
                 String.contains?(entry, job_label)
               end)}
            end)
          end)
          |> Enum.map(fn t ->
            case Task.await(t) do
              {filename, nil} ->
                %{filename: filename, pid: nil, status: nil, label: nil}

              {filename, status} ->
                [pid, status, label] = String.split(status, "\t")
                %{filename: filename, pid: pid, status: status, label: label}
            end
          end)

        files_list_keys =
          files
          |> Enum.map(fn %{filename: filename} ->
            filename
          end)
          |> Enum.into(MapSet.new())

        unfold_map_keys =
          socket.assigns.unfold_map
          |> Map.keys()
          |> Enum.into(MapSet.new())

        unfold_map_keys_to_delete = MapSet.difference(unfold_map_keys, files_list_keys)

        unfold_map =
          Enum.reduce(unfold_map_keys_to_delete, socket.assigns.unfold_map, fn k, map ->
            Map.delete(map, k)
          end)

        socket
        |> assign(launchd_files: files, unfold_map: unfold_map)

      {:error, reason} ->
        socket
        |> put_flash(:error, "put_launchd_files: #{reason}")
    end
  end
end
