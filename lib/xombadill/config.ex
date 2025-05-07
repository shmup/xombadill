defmodule Xombadill.Config do
  @moduledoc """
  State manager for global Xombadill configuration using GenServer.

  Holds the global config (e.g., default server and channel),
  and provides helper functions for broadcasting messages in a consistent way.
  """
  use GenServer

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def get_default_server do
    GenServer.call(__MODULE__, :get_default_server)
  end

  def get_default_channel do
    GenServer.call(__MODULE__, :get_default_channel)
  end

  @doc """
  Send a message to the default server and channel.
  """
  def say(message) do
    server = get_default_server()
    channel = get_default_channel()
    Xombadill.IrcClient.say(server, channel, message)
  end

  @impl true
  def init(config) do
    {:ok, config}
  end

  @impl true
  def handle_call(:get_default_server, _from, config) do
    {:reply, config.default_server, config}
  end

  @impl true
  def handle_call(:get_default_channel, _from, config) do
    {:reply, config.default_channel, config}
  end
end
