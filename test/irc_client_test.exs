defmodule Xombadill.IrcClientTest do
  use ExUnit.Case, async: false
  @moduletag :irc_client

  alias Xombadill.IrcClient

  setup do
    # Register test process
    Process.register(self(), IrcClientTest)

    # Mock ExIRC functionality - keep the reference to help with testing
    mock_client = self()

    # Define a module for mocking
    defmodule(MockExIRC, do: nil)

    # Re-define ExIRC.Client for the test
    defmodule ExIRC.Client do
      def start_link!() do
        {:ok, Process.whereis(IrcClientTest)}
      end

      def add_handler(_, _) do
        :ok
      end

      def connect!(_, _, _) do
        :ok
      end

      def logon(_, nick, user, name, password) do
        send(Process.whereis(IrcClientTest), {:logon, nick, user, name, password})
        :ok
      end

      def join(_, _) do
        :ok
      end
    end

    # Ensure we have a Registry
    unless Process.whereis(Xombadill.IrcRegistry) do
      start_supervised!({Registry, keys: :unique, name: Xombadill.IrcRegistry})
    end

    # Make it possible to use the IrcClient with our mock
    opts = %{
      host: "test.host.com",
      port: 6667,
      nick: "test_bot",
      channels: ["#test"],
      server_id: :test_server,
      exirc_module: MockExIRC
    }

    {:ok, client_pid} = IrcClient.start_link(opts)

    %{
      client_pid: client_pid,
      mock_client: mock_client
    }
  end

  test "handles connection message", %{client_pid: client_pid} do
    # Simulate receiving connection message from ExIRC
    send(client_pid, {:connected, "test.host.com", 6667})

    # Verify the client attempts to log in
    assert_receive {:logon, "test_bot", "test_bot", "test_bot", "test_bot"}
  end

  test "handles channel messages", %{client_pid: client_pid} do
    # Setup a mock HandlerRegistry directly
    defmodule MockHandlerRegistry do
      def handle_message(type, message) do
        send(Process.whereis(IrcClientTest), {:handler_registry_received, type, message})
        :ok
      end
    end

    # Override the handler registry module
    Application.put_env(:xombadill, :handler_registry, MockHandlerRegistry)

    # Simulate a channel message
    sender_info = %{nick: "user", user: "user", host: "user.host"}
    send(client_pid, {:received, "hello bot", sender_info, "#test"})

    # Verify the message was sent to the handler registry
    assert_receive {:handler_registry_received, :channel_message,
                    %{
                      text: "hello bot",
                      nick: "user",
                      channel: "#test"
                    }}
  end
end
