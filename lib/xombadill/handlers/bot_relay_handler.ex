defmodule Xombadill.Handlers.BotRelayHandler do
  @moduledoc """
  Handler for relaying commands to bots (e.g. Sequell, Henzell, etc) by using the !!, ??, or similar command prefix in a public channel.
  New functionality: route requests from #splat to the correct bot on the right server, PM them, and relay replies back.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger

  # Supported prefixes that trigger a relay; most common are !!, ??, etc
  @relay_prefixes ["!!", "??", "%%", "@??", "@", "!", "%", "=", "$", "^", "&&"]
  # Bot mapping for prefixes to bot nick on libera IRC
  @bot_map %{
    "!!" => "Sequell",
    "??" => "Sequell",
    "%%" => "Cheibriados",
    "@??" => "Gretell",
    "@" => "Gretell",
    "!" => "Henzell",
    "%" => "Sizzell",
    "&&" => "Sequell",
    "=" => "Jorgrell",
    "$" => "Lantell",
    "^" => "Rotatell"
  }
  # Accept both #splat and PM relay responses
  @input_channel "#splat"
  @libera_id :libera
  @bot_pm_timeout 3500

  @impl true
  def handle_message(:channel_message, %{
        text: text,
        nick: nick,
        channel: channel,
        server_id: server_id
      })
      when server_id == :slashnet and channel == @input_channel do
    parse_and_relay(text, nick, channel)
  end

  @impl true
  def handle_message(:private_message, %{text: text, nick: bot_nick}) do
    # PM from libera bot to our nick, forward to #splat
    Logger.debug("RelayHandler: Got PM from #{bot_nick}: #{text}")
    Xombadill.Config.say("[#{bot_nick}] #{text}")
    :ok
  end

  @impl true
  def handle_message(_, _), do: :ok

  # Step 1: Parse prefix and recognized bot command, relay to right bot as PM
  defp parse_and_relay(text, sender_nick, channel) do
    # Try to parse supported prefixes; catch direct bot address or pm-style too
    case parse_bot_command(text) do
      {bot_nick, relay_line} ->
        # We are SENDING the relay command via PM to libera bot nick
        Logger.info(
          "Relaying '#{relay_line}' from #{sender_nick} to #{bot_nick} via PM on libera"
        )

        pm_and_relay(bot_nick, relay_line, sender_nick, channel)

      nil ->
        Logger.debug("BotRelayHandler: Not a relay command: #{text}")
        :ok
    end
  end

  # Step 2: Actually send the PM to the target bot (on libera) and setup response relay
  defp pm_and_relay(bot_nick, line, sender_nick, channel) do
    libera_client = get_libera_client()

    if libera_client do
      # PM bot_nick with the command; optionally prefix sender_nick for !RELAY context
      # Example: '!!lg someplayer' becomes PM 'lg someplayer' to Sequell
      ExIRC.Client.msg(libera_client, :privmsg, bot_nick, line)
      Logger.debug("PM sent to #{bot_nick} on libera: #{inspect(line)}")
      # Setup relay process to catch PM reply and bounce it back to #splat
      spawn(fn ->
        relay_libera_pm_response(bot_nick, sender_nick, channel)
      end)
    else
      Logger.warning("Could not relay: Libera client not found.")
      :ok
    end
  end

  # Step 3: Wait briefly for bot pm reply; echo it to #splat (from this bot)
  defp relay_libera_pm_response(bot_nick, sender_nick, _channel) do
    receive do
      {:libera_bot_reply, ^bot_nick, reply_line} ->
        Xombadill.Config.say("[relay from #{bot_nick} for #{sender_nick}] #{reply_line}")
    after
      @bot_pm_timeout ->
        Logger.debug(
          "RelayHandler: Did not receive bot reply from #{bot_nick} in #{@bot_pm_timeout}ms"
        )

        :timeout
    end
  end

  defp get_libera_client do
    case Registry.lookup(Xombadill.IrcRegistry, @libera_id) do
      [{pid, _}] ->
        %{client: client} = :sys.get_state(pid)
        client

      _ ->
        Logger.error("Libera IRC client not found for relay")
        nil
    end
  end

  @doc false
  # Regex (and known map) mappings for standard prefixes; call for any message
  def parse_bot_command(text) do
    Enum.find_value(@relay_prefixes, fn prefix ->
      if String.starts_with?(text, prefix) and String.length(text) > String.length(prefix) do
        bot_nick = Map.get(@bot_map, prefix, nil) || "Sequell"
        relay_line = String.trim_leading(text, prefix) |> String.trim()
        {bot_nick, relay_line}
      else
        nil
      end
    end)
  end
end
