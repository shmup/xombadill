defmodule Xombadill.Handlers.ReloadHandler do
  @behaviour Xombadill.HandlerBehaviour
  require Logger
  alias Xombadill.ReloadCoordinator

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client} = _msg) do
    cond do
      text == "!reload" ->
        Task.start(fn -> ReloadCoordinator.reload_all_handlers(channel, client) end)

      true ->
        :ok
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok
end
