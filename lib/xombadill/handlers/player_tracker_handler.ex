defmodule Xombadill.Handlers.PlayerTrackerHandler do
  @moduledoc """
  Handler to allow channel commands to manage the list of tracked players for milestones.

  Provides `!watch`, `!unwatch`, and `!watched` commands to control which players are actively
  being followed in milestone broadcasts.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(
        :channel_message,
        %{text: text} = _msg
      ) do
    cond do
      String.starts_with?(text, "!watch ") ->
        player = String.trim(String.replace(text, "!watch ", ""))
        handle_watch_command(player)
        :stop

      String.starts_with?(text, "!unwatch ") ->
        player = String.trim(String.replace(text, "!unwatch ", ""))
        handle_unwatch_command(player)
        :stop

      text == "!watched" ->
        handle_watched_command()
        :stop

      true ->
        :ok
    end
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
end
