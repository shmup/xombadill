defmodule Xombadill.Handlers.MilestoneHandler do
  @moduledoc """
  Handler that relays DCSS (Dungeon Crawl Stone Soup) deaths and other milestone notifications
  from Libera IRC (#crawl-octolog, #pissss) to the configured channel based on tracked player patterns.

  It highlights death announcements and also echoes messages relating to watched players.
  """

  @behaviour Xombadill.HandlerBehaviour
  require Logger

  # IRC formatting codes
  @bold "\x02"
  @pink "\x0313"
  @cyan "\x0311"
  @reset "\x0F"

  @impl true
  def handle_message(
        :channel_message,
        %{
          text: text,
          channel: channel,
          server_id: server_id
        } = _msg
      ) do
    if server_id == :libera && channel in ["#crawl-octolog", "#pissss"] do
      cond do
        is_new_run_message?(text) && is_tracked_player_message?(text) ->
          formatted_message = format_new_run_message(text)
          Xombadill.Config.say(formatted_message)

        is_death_message?(text) && is_tracked_player_message?(text) ->
          formatted_message = format_death_message(text)
          Xombadill.Config.say(formatted_message)

        is_tracked_player_message?(text) ->
          Xombadill.Config.say(text)

        true ->
          :ok
      end
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok

  defp is_new_run_message?(text) do
    Regex.match?(~r/^\w+\s+\(L\d+\s+\w+\)\s+began the quest for the Orb\./, text)
  end

  defp is_death_message?(text) do
    Regex.match?(~r/\(L\d+.*\).*with \d+ points after \d+ turns and \d+:\d+:\d+\./, text)
  end

  defp is_tracked_player_message?(text) do
    tracked_players = Xombadill.TrackedPlayers.list()

    Enum.any?(tracked_players, fn player ->
      Regex.match?(~r/^#{Regex.escape(player)}\s+\(L\d+/, text) ||
        Regex.match?(~r/^#{Regex.escape(player)}\s+the\s+\w+\s+\(L\d+/, text) ||
        Regex.match?(~r/ghost of #{Regex.escape(player)}/, text)
    end)
  end

  defp format_new_run_message(text) do
    "#{@bold}#{@cyan}#{text}#{@reset}"
  end

  defp format_death_message(text) do
    "#{@bold}#{@pink}#{text}#{@reset}"
  end
end
