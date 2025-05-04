defmodule Xombadill.ReloadCoordinatorTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Xombadill.ReloadCoordinator

  setup do
    # Create a mock registry
    mock_registry = :mox.defmock(MockHandlerRegistry, for: Xombadill.HandlerRegistryBehaviour)
    :mox.stub(MockHandlerRegistry, :unregister, fn _ -> :ok end)
    :mox.stub(MockHandlerRegistry, :register, fn _ -> :ok end)

    # Override the handler registry module
    Application.put_env(:xombadill, :handler_registry, MockHandlerRegistry)

    # Mock Config.say
    mock_config = :mox.defmock(MockConfig, for: Xombadill.ConfigBehaviour)
    :mox.stub(MockConfig, :say, fn message -> send(self(), {:config_say, message}) end)

    Application.put_env(:xombadill, :config, MockConfig)

    # Creating a test module that can be reloaded
    module_code = """
    defmodule Xombadill.Handlers.TestHandler do
      @behaviour Xombadill.HandlerBehaviour
      def handle_message(_, _), do: :ok
    end
    """

    file_path = "lib/xombadill/handlers/test_handler.ex"
    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, module_code)

    on_exit(fn ->
      File.rm(file_path)
    end)

    %{client: self(), channel: "#test"}
  end

  test "reload_module successfully reloads a module", %{client: client, channel: channel} do
    output =
      capture_log(fn ->
        ReloadCoordinator.reload_module("Xombadill.Handlers.TestHandler", channel, client)

        assert_receive {:config_say,
                        "✅ Module Xombadill.Handlers.TestHandler reloaded successfully"}
      end)

    assert output =~ "Attempting to reload module: Xombadill.Handlers.TestHandler"
  end

  test "reload_module handles errors gracefully", %{client: client, channel: channel} do
    output =
      capture_log(fn ->
        ReloadCoordinator.reload_module("Xombadill.NonExistentModule", channel, client)
        assert_receive {:msg, :privmsg, "#test", message}
        assert message =~ "❌ Error reloading Xombadill.NonExistentModule"
      end)

    assert output =~ "Failed to reload module"
  end
end
