defmodule Xombadill.Handlers.EchoHandlerTest do
  use ExUnit.Case
  @moduletag :echo_test

  alias Xombadill.Handlers.EchoHandler

  setup do
    Process.register(self(), EchoHandlerTest)
    :ok
  end

  # Mock the ExIRC.Client
  defmodule MockClient do
    def msg(_client, cmd, channel, text) do
      send(Process.whereis(EchoHandlerTest), {:msg, cmd, channel, text})
      :ok
    end
  end

  test "echoes messages from #splat" do
    message = %{
      text: "hello",
      nick: "tester",
      channel: "#splat",
      client: MockClient
    }

    # Test with our mock
    ExUnit.CaptureLog.capture_log(fn ->
      EchoHandler.handle_message(:channel_message, message)
      assert_receive {:msg, :privmsg, "#splat", "tester said: hello"}
    end)
  end

  test "doesn't echo commands" do
    message = %{
      text: "!command",
      nick: "tester",
      channel: "#splat",
      client: MockClient
    }

    ExUnit.CaptureLog.capture_log(fn ->
      EchoHandler.handle_message(:channel_message, message)
      refute_receive {:msg, :privmsg, "#splat", _}
    end)
  end
end
