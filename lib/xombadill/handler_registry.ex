defmodule Xombadill.HandlerRegistry do
  @moduledoc """
  Registry for IRC message handlers.
  Allows dynamic registration and management of handlers while the bot is running.
  """
  use GenServer
  require Logger

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a new handler module.
  """
  def register(module) when is_atom(module) do
    GenServer.call(__MODULE__, {:register, module})
  end

  @doc """
  Unregister a handler module.
  """
  def unregister(module) when is_atom(module) do
    GenServer.call(__MODULE__, {:unregister, module})
  end

  @doc """
  List all registered handlers.
  """
  def list_handlers do
    GenServer.call(__MODULE__, :list_handlers)
  end

  @doc """
  Process a message through all registered handlers.
  """
  def handle_message(type, message) do
    GenServer.cast(__MODULE__, {:handle_message, type, message})
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    initial_handlers = Keyword.get(opts, :default_handlers, [])
    # Consider adding checks here to ensure modules exist and implement the behaviour if needed
    Logger.info("Initializing HandlerRegistry with handlers: #{inspect(initial_handlers)}")
    {:ok, %{handlers: initial_handlers}}
  end

  @impl true
  def handle_call({:register, module}, _from, state) do
    if module in state.handlers do
      {:reply, {:error, :already_registered}, state}
    else
      Logger.info("Registered handler: #{inspect(module)}")
      {:reply, :ok, %{state | handlers: [module | state.handlers]}}
    end
  end

  @impl true
  def handle_call({:unregister, module}, _from, state) do
    if module in state.handlers do
      Logger.info("Unregistered handler: #{inspect(module)}")
      {:reply, :ok, %{state | handlers: state.handlers -- [module]}}
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  @impl true
  def handle_call(:list_handlers, _from, state) do
    {:reply, state.handlers, state}
  end

  def handle_cast({:handle_message, type, message}, state) do
    Logger.debug("HandlerRegistry processing: #{inspect(type)}, message: #{inspect(message)}")

    # Important: add debug logs to see what's in state.handlers
    Logger.debug("Current handlers: #{inspect(state.handlers)}")

    Enum.each(state.handlers, fn module ->
      try do
        Logger.debug("Calling handler: #{inspect(module)}")
        module.handle_message(type, message)
      rescue
        e ->
          Logger.error("Error in handler #{inspect(module)}: #{inspect(e)}")
      end
    end)

    {:noreply, state}
  end
end
