defmodule Xombadill.Handlers.EchoHandlerTest do
  use ExUnit.Case

  alias Xombadill.Handlers.EchoHandler

  test "echoes messages from #splat" do
    message = %{
      text: "hello",
      nick: "tester",
      channel: "#splat",
      # We'll use the test process as the mock client
      client: self()
    }

    # Mock ExIRC.Client.msg behavior
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
      client: self()
    }

    ExUnit.CaptureLog.capture_log(fn ->
      EchoHandler.handle_message(:channel_message, message)
      refute_receive {:msg, :privmsg, "#splat", _}
    end)
  end
end
