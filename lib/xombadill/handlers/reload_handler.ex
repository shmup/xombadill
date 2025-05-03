defmodule Xombadill.Handlers.ReloadHandler do
  @behaviour Xombadill.HandlerBehaviour
  require Logger
  alias Xombadill.ReloadCoordinator

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client} = _msg) do
    cond do
      String.starts_with?(text, "!reload ") ->
        module_name = String.trim_leading(text, "!reload ") |> String.trim()
        # Use Task.start to avoid blocking the handler
        Task.start(fn -> ReloadCoordinator.reload_module(module_name, channel, client) end)

      text == "!reload" ->
        Task.start(fn -> ReloadCoordinator.reload_all_handlers(channel, client) end)

      true ->
        :ok
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok
end
