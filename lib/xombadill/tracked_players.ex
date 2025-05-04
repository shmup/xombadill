defmodule Xombadill.TrackedPlayers do
  use GenServer
  require Logger

  @db_dir "cubdb/tracked_players"

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def track(nick) do
    GenServer.call(__MODULE__, {:track, nick})
  end

  def untrack(nick) do
    GenServer.call(__MODULE__, {:untrack, nick})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def tracked?(nick) do
    GenServer.call(__MODULE__, {:tracked?, nick})
  end

  # Server Callbacks
  @impl true
  def init(_) do
    # Ensure directory exists
    File.mkdir_p!(@db_dir)

    case CubDB.start_link(@db_dir) do
      {:ok, db} ->
        Logger.info("TrackedPlayers database initialized")
        {:ok, %{db: db}}

      {:error, reason} ->
        Logger.error("Failed to start TrackedPlayers database: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:track, nick}, _from, %{db: db} = state) do
    CubDB.put(db, "players", [nick | list_from_db(db)] |> Enum.uniq())
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:untrack, nick}, _from, %{db: db} = state) do
    players = list_from_db(db)
    CubDB.put(db, "players", players -- [nick])
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:list, _from, %{db: db} = state) do
    {:reply, list_from_db(db), state}
  end

  @impl true
  def handle_call({:tracked?, nick}, _from, %{db: db} = state) do
    result = nick in list_from_db(db)
    {:reply, result, state}
  end

  defp list_from_db(db) do
    CubDB.get(db, "players", [])
  end
end
