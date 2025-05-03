defmodule Xombadill.Handlers.ReloadHandler do
  @moduledoc """
  Handler that reloads modules when !reload command is used
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client}) do
    cond do
      String.starts_with?(text, "!reload ") ->
        module_name = String.trim_leading(text, "!reload ") |> String.trim()
        reload_module(module_name, channel, client)

      text == "!reload" ->
        reload_all_handlers(channel, client)

      true ->
        :ok
    end
  end

  def handle_message(_type, _message), do: :ok

  defp reload_module(module_name, channel, client) do
    Logger.info("Attempting to reload module: #{module_name}")

    try do
      # Convert string to module atom
      module = String.to_existing_atom("Elixir." <> module_name)

      # Unregister from registry
      Xombadill.HandlerRegistry.unregister(module)

      # Reload code
      Code.purge(module)
      Code.load_file(module_name |> String.downcase() |> String.replace(".", "/") |> Kernel.<>(".ex"))

      # Register again
      Xombadill.HandlerRegistry.register(module)

      ExIRC.Client.msg(client, :privmsg, channel, "✅ Module #{module_name} reloaded successfully")
    rescue
      e ->
        Logger.error("Failed to reload module #{module_name}: #{inspect(e)}")
        ExIRC.Client.msg(client, :privmsg, channel, "❌ Error reloading #{module_name}: #{inspect(e)}")
    end
  end

  defp reload_all_handlers(channel, client) do
    Logger.info("Reloading all handlers")

    handlers = Xombadill.HandlerRegistry.list_handlers()

    Enum.each(handlers, fn module ->
      module_name = Atom.to_string(module) |> String.replace_prefix("Elixir.", "")
      reload_module(module_name, channel, client)
    end)

    ExIRC.Client.msg(client, :privmsg, channel, "✅ Attempted to reload #{length(handlers)} handlers")
  end
end
