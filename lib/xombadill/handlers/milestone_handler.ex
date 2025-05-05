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
          channel: channel,
          server_id: server_id
        } = _msg
      ) do
    if server_id == :libera && channel in ["#crawl-octolog", "#pissss"] do
      cond do
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

  defp format_death_message(text) do
    "#{@bold}#{@pink}#{text}#{@reset}"
  end
end
