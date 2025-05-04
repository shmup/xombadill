defmodule Xombadill.Handlers.MilestoneHandler do
  @moduledoc """
  A handler that relays DCSS deaths and other milestones from Libera/#crawl-octolog
  to the configured channel based on certain patterns or tracked players.
  Also handles commands to manage tracked players.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger

  # IRC formatting codes
  @bold "\x02"
  @pink "\x0313"
  @reset "\x0F"

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
      String.starts_with?(text, "!watch ") ->
        player = String.trim(String.replace(text, "!watch ", ""))
        handle_watch_command(player)

      String.starts_with?(text, "!unwatch ") ->
        player = String.trim(String.replace(text, "!unwatch ", ""))
        handle_unwatch_command(player)

      text == "!watched" ->
        handle_watched_command()

      server_id == :libera && channel == "#crawl-octolog" ->
        cond do
          is_death_message?(text) && is_tracked_player_message?(text) ->
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

    Enum.any?(tracked_players, fn player ->
      # Match "Player (L12 MiAl)" pattern - player is the primary character
      # Match "ghost of Player" pattern
      Regex.match?(~r/#{Regex.escape(player)}\s+\(L\d+/, text) ||
        Regex.match?(~r/ghost of #{Regex.escape(player)}/, text)
    end)
  end

  defp format_death_message(text) do
    "#{@bold}#{@pink}#{text}#{@reset}"
  end
end
