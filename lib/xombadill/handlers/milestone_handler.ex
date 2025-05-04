defmodule Xombadill.Handlers.MilestoneHandler do
  @moduledoc """
  A handler that relays DCSS deaths and other milestones from Libera/#crawl-octolog
  to the configured channel based on certain patterns or tracked players.
  Also handles commands to manage tracked players.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(
        :channel_message,
        %{
          text: text,
          nick: _sender_nick,
          channel: channel,
          server_id: server_id,
          server_host: _server_host
        } = _msg
      ) do
    cond do
      # Handle !watch, !unwatch, !watched commands from any channel/server
      String.starts_with?(text, "!watch ") ->
        player = String.trim(String.replace(text, "!watch ", ""))
        handle_watch_command(player)

      String.starts_with?(text, "!unwatch ") ->
        player = String.trim(String.replace(text, "!unwatch ", ""))
        handle_unwatch_command(player)

      text == "!watched" ->
        handle_watched_command()

      # Only process milestone messages from Libera/#crawl-octolog
      server_id == :libera && channel == "#crawl-octolog" ->
        cond do
          is_death_message?(text) ->
            formatted_message = format_death_message(text)
            Xombadill.Config.say(formatted_message)

          is_tracked_player_message?(text) ->
            Xombadill.Config.say("#tracked #{text}")

          true ->
            :ok
        end

      true ->
        :ok
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok

  defp handle_watch_command(player) do
    if player != "" do
      Xombadill.TrackedPlayers.track(player)
      Xombadill.Config.say("Now watching #{player}")
    end
  end

  defp handle_unwatch_command(player) do
    if player != "" do
      Xombadill.TrackedPlayers.untrack(player)
      Xombadill.Config.say("No longer watching #{player}")
    end
  end

  defp handle_watched_command do
    players = Xombadill.TrackedPlayers.list()

    case players do
      [] ->
        Xombadill.Config.say("No players being watched")

      players ->
        player_list = Enum.join(players, ", ")
        Xombadill.Config.say("Watching: #{player_list}")
    end
  end

  defp is_death_message?(text) do
    Regex.match?(~r/\(L\d+\s+\w+\w+\).+with\s+\d+\s+points\s+after\s+\d+\s+turns/, text)
  end

  defp is_tracked_player_message?(text) do
    tracked_players = Xombadill.TrackedPlayers.list()

    cond do
      # Match "Player (L12 MiAl)" pattern - player is the primary character
      Enum.any?(tracked_players, fn player ->
        Regex.match?(~r/#{Regex.escape(player)}\s+\(L\d+/, text)
      end) ->
        true

      # Match "ghost of Player" pattern
      Enum.any?(tracked_players, fn player ->
        Regex.match?(~r/ghost of #{Regex.escape(player)}/, text)
      end) ->
        true

      true ->
        false
    end
  end

  defp format_death_message(text) do
    "#splat #{text}"
  end
end
