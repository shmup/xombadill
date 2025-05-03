defmodule Xombadill.IrcClient do
  use GenServer
  require Logger
  alias Xombadill.HandlerRegistry

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Send a message to a channel.
  """
  def say(channel, message) do
    GenServer.cast(__MODULE__, {:say, channel, message})
  end

  @doc """
  Join a channel.
  """
  def join(channel) do
    GenServer.cast(__MODULE__, {:join, channel})
  end

  @doc """
  Leave a channel.
  """
  def leave(channel) do
    GenServer.cast(__MODULE__, {:leave, channel})
  end

  @doc """
  Get the current state of the IRC client.
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @impl true
  def init(opts) do
    {:ok, client} = ExIRC.start_link!()

    state = %{
      client: client,
      host: opts[:host] || "irc.slashnet.org",
      port: opts[:port] || 6667,
      nick: opts[:nick] || "xombadill",
      channels: opts[:channels] || ["#splat"]
    }

    ExIRC.Client.add_handler(client, self())
    ExIRC.Client.connect!(client, state.host, state.port)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:say, channel, message}, state) do
    ExIRC.Client.msg(state.client, :privmsg, channel, message)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:join, channel}, state) do
    ExIRC.Client.join(state.client, channel)
    {:noreply, %{state | channels: [channel | state.channels] |> Enum.uniq()}}
  end

  @impl true
  def handle_cast({:leave, channel}, state) do
    ExIRC.Client.part(state.client, channel)
    {:noreply, %{state | channels: state.channels -- [channel]}}
  end

  # handle connection messages
  @impl true
  def handle_info({:connected, server, port}, state) do
    Logger.info("Connected to #{server}:#{port}")
    ExIRC.Client.logon(state.client, state.nick, state.nick, state.nick, state.nick)
    {:noreply, state}
  end

  # handle login success
  def handle_info(:logged_in, state) do
    Logger.info("Logged in to server")

    Enum.each(state.channels, fn channel ->
      ExIRC.Client.join(state.client, channel)
    end)

    {:noreply, state}
  end

  # handle disconnection
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("Disconnected: #{inspect(reason)}", [])
    # Attempt to reconnect after a delay
    Process.send_after(self(), :connect, 5000)
    {:noreply, state}
  end

  # reconnection handler
  def handle_info(:connect, state) do
    Logger.info("Attempting to connect to #{state.host}:#{state.port}")
    ExIRC.Client.connect!(state.client, state.host, state.port)
    {:noreply, state}
  end

  # handle joining a channel
  def handle_info({:joined, channel}, state) do
    Logger.info("Joined channel: #{channel}")
    {:noreply, state}
  end

  # handle public messages
  def handle_info({:received, msg, %{nick: nick, user: user, host: host}, channel}, state) do
    Logger.info("#{channel} #{nick}: #{msg}", truncate: :infinity)

    HandlerRegistry.handle_message(:channel_message, %{
      text: msg,
      nick: nick,
      user: user,
      host: host,
      channel: channel,
      client: state.client
    })

    {:noreply, state}
  end

  # handle private messages
  def handle_info({:received, msg, info}, state) do
    Logger.info("PRIVATE #{info.nick}: #{msg}", truncate: :infinity)

    # Pass to handler registry
    HandlerRegistry.handle_message(:private_message, %{
      text: msg,
      nick: info.nick,
      user: info.user,
      host: info.host,
      client: state.client
    })

    {:noreply, state}
  end

  # handle nick changes
  def handle_info({:nick_changed, old_nick, new_nick}, state) do
    Logger.info("Nick changed from #{old_nick} to #{new_nick}")

    HandlerRegistry.handle_message(:nick_changed, %{
      old_nick: old_nick,
      new_nick: new_nick,
      client: state.client
    })

    {:noreply, state}
  end

  # handle users joining channels
  def handle_info({:joined, channel, user}, state) do
    Logger.debug("#{user} joined #{channel}")

    HandlerRegistry.handle_message(:user_joined, %{
      user: user,
      channel: channel,
      client: state.client
    })

    {:noreply, state}
  end

  # handle users leaving channels
  def handle_info({:left, channel, user}, state) do
    Logger.debug("#{user} left #{channel}")

    HandlerRegistry.handle_message(:user_left, %{
      user: user,
      channel: channel,
      client: state.client
    })

    {:noreply, state}
  end

  # handle users quitting the server
  def handle_info({:quit, user, message}, state) do
    Logger.debug("#{user} quit: #{message}")

    HandlerRegistry.handle_message(:user_quit, %{
      user: user,
      message: message,
      client: state.client
    })

    {:noreply, state}
  end

  # catch-all for messages
  def handle_info(_msg, state) do
    # Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
