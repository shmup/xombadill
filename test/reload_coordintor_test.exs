defmodule Xombadill.ReloadCoordinatorTest do
  use ExUnit.Case, async: false
  @moduletag :reload_coordinator
  import ExUnit.CaptureLog

  alias Xombadill.ReloadCoordinator

  setup do
    # Configure the mocks
    Mox.stub(MockHandlerRegistry, :unregister, fn _ -> :ok end)
    Mox.stub(MockHandlerRegistry, :register, fn _ -> :ok end)

    # Override the handler registry module
    Application.put_env(:xombadill, :handler_registry, MockHandlerRegistry)

    # Mock Config.say
    Mox.stub(MockConfig, :say, fn message -> send(self(), {:config_say, message}) end)

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

  # Create a mock for ExIRC.Client.msg
  defmodule MockMessageClient do
    def msg(_client, _cmd, _channel, text) do
      test_pid = Process.whereis(ReloadTest)
      if test_pid, do: send(test_pid, {:msg, text})
      :ok
    end
  end

  setup do
    Process.register(self(), ReloadTest)
    :ok
  end

  # Patch test versions of the functions we need
  defmodule ExIRC.Client do
    def msg(client, cmd, channel, message) do
      MockMessageClient.msg(client, cmd, channel, message)
    end
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
        assert_receive {:msg, message}
        assert message =~ "❌ Error reloading Xombadill.NonExistentModule"
      end)

    assert output =~ "Failed to reload module"
  end
end
