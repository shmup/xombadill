defmodule Xombadill.Handlers.BotRelayHandler do
  @moduledoc """
  Handler for relaying commands to bots (e.g. Sequell, Henzell, etc) by using the !!, ??, or similar
  command prefix in a public channel, and routing their responses back to the original channel.
  """

  @relay_registry Xombadill.BotRelayRegistry

  @behaviour Xombadill.HandlerBehaviour
  require Logger

  # Supported prefixes that trigger a relay
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
    "^" => "Cbrotelljr"
  }
  @input_channel "#splat"
  @libera_id :libera
  @bot_pm_timeout 5000

  @impl true
  def handle_message(type, message) do
    case {type, message} do
      # Handle commands from #splat on slashnet
      {:channel_message, %{text: text, nick: nick, channel: @input_channel, server_id: :slashnet}} ->
        handle_possible_command(text, nick)

      # Handle PMs from bots on Libera - more permissive matching
      {:private_message, %{nick: bot_nick, text: text}} ->
        Logger.info("Got PM from #{bot_nick}: #{text}")
        # Relay to registered processes only
        Registry.dispatch(@relay_registry, bot_nick, fn entries ->
          for {pid, _} <- entries do
            send(pid, {:libera_bot_reply, bot_nick, text})
          end
        end)

        :ok

      _ ->
        :ok
    end
  end

  # Process commands from users in #splat
  defp handle_possible_command(text, sender_nick) do
    case parse_bot_command(text) do
      {bot_nick, relay_line} ->
        pm_and_relay(bot_nick, relay_line, sender_nick)

      nil ->
        :ok
    end
  end

  # Send PM to the bot and setup response relay
  defp pm_and_relay(bot_nick, line, sender_nick) do
    libera_client = get_libera_client()

    if libera_client do
      # Use a separate Task for better isolation and error handling
      Task.start(fn ->
        # Register ONLY this specific process with the registry for the bot
        Registry.register(@relay_registry, bot_nick, nil)

        # Send the message to the bot
        ExIRC.Client.msg(libera_client, :privmsg, bot_nick, line)

        # Wait for response
        relay_libera_pm_response(bot_nick, sender_nick)

        # Clean up by unregistering when done
        Registry.unregister(@relay_registry, bot_nick)
      end)
    else
      Logger.warning("Could not relay: Libera client not found.")
      :ok
    end
  end

  # Wait for bot PM reply and relay it to the channel
  defp relay_libera_pm_response(bot_nick, _sender_nick) do
    receive do
      {:libera_bot_reply, ^bot_nick, reply_line} ->
        Xombadill.Config.say("#{reply_line}")
    after
      @bot_pm_timeout -> :timeout
    end
  end

  defp get_libera_client do
    case Registry.lookup(Xombadill.IrcRegistry, @libera_id) do
      [{pid, _}] ->
        %{client: client} = :sys.get_state(pid)
        client

      _ ->
        nil
    end
  end

  # Parse bot command from text
  def parse_bot_command(text) do
    Enum.find_value(@relay_prefixes, fn prefix ->
      if String.starts_with?(text, prefix) and String.length(text) > String.length(prefix) do
        bot_nick = Map.get(@bot_map, prefix, "Sequell")
        {bot_nick, text}
      else
        nil
      end
    end)
  end
end
