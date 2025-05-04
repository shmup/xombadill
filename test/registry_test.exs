defmodule Xombadill.HandlerRegistryTest do
  use ExUnit.Case

  alias Xombadill.HandlerRegistry

  defmodule MockHandler do
    @behaviour Xombadill.HandlerBehaviour
    def handle_message(type, message) do
      if Process.whereis(RegistryTest) do
        send(Process.whereis(RegistryTest), {:mock_handler, type, message})
      end

      :ok
    end
  end

  setup do
    Process.register(self(), RegistryTest)
    # Start a clean registry for testing
    # Only try to stop if it exists
    try do
      if Process.whereis(HandlerRegistry) do
        GenServer.stop(HandlerRegistry, :normal)
      end
    rescue
      _ -> :ok
    end

    start_supervised!({HandlerRegistry, [default_handlers: []]})
    :ok
  end

  test "registers and unregisters handlers" do
    assert HandlerRegistry.list_handlers() == []
    assert :ok = HandlerRegistry.register(MockHandler)
    assert HandlerRegistry.list_handlers() == [MockHandler]
    assert :ok = HandlerRegistry.unregister(MockHandler)
    assert HandlerRegistry.list_handlers() == []
  end

  test "dispatches messages to registered handlers" do
    HandlerRegistry.register(MockHandler)

    message = %{text: "test", nick: "tester", channel: "#test"}
    HandlerRegistry.handle_message(:channel_message, message)

    assert_receive {:mock_handler, :channel_message, ^message}
  end
end
