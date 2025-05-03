defmodule Xombadill.Handlers.ReloadHandler do
  @moduledoc """
  Handler that reloads modules when !reload command is used
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  @impl true
  def handle_message(:channel_message, %{text: text, channel: channel, client: client, nick: _nick} = _msg) do
    cond do
      String.starts_with?(text, "!reload ") ->
        module_name = String.trim_leading(text, "!reload ") |> String.trim()
        # Use spawn to avoid deadlock
        spawn(fn -> reload_module(module_name, channel, client) end)
      text == "!reload" ->
        # Use spawn to avoid deadlock
        spawn(fn -> reload_all_handlers(channel, client) end)
      true ->
        :pass # Let other handlers (like EchoHandler) see all messages as well
    end
    :ok
  end

  def handle_message(_type, _message), do: :ok

  defp reload_module(module_name, channel, client) do
    Logger.info("Attempting to reload module: #{module_name}")
    try do
      # Convert string to module atom
      module = String.to_existing_atom("Elixir." <> module_name)

      # Unregister from registry
      Xombadill.HandlerRegistry.unregister(module)

      # Reload code - using proper functions
      :code.purge(module)
      :code.delete(module)

      # Build file_path relative to lib directory (the correct one)
      # Convert module name to snake_case and path
      file_path = 
        module_name
        |> Macro.underscore()
        |> String.replace(".", "/")
        |> (&("lib/xombadill/handlers/" <> &1 <> ".ex")).()

      # Compile and reload
      Code.compile_file(file_path)

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
    handlers =
      try do
        :sys.get_state(Xombadill.HandlerRegistry).handlers
      rescue
        _ -> []
      end
    Enum.each(handlers, fn module ->
      module_name = Atom.to_string(module) |> String.replace_prefix("Elixir.", "")
      reload_module(module_name, channel, client)
    end)
    ExIRC.Client.msg(client, :privmsg, channel, "✅ Attempted to reload #{length(handlers)} handlers")
  end
end
