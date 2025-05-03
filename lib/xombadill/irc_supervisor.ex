defmodule Xombadill.IrcSupervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(servers) do
    children =
      Enum.map(servers, fn {server_id, config} ->
        %{
          id: server_id,
          start: {Xombadill.IrcClient, :start_link, [Map.put(config, :server_id, server_id)]}
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_client(server_id) do
    Xombadill.IrcClient.via_tuple(server_id)
  end
end
