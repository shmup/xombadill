defmodule Xombadill.IrcClientTest do
  use ExUnit.Case

  alias Xombadill.IrcClient

  setup do
    # Mock ExIRC functionality
    mock_client = self()

    mock_module = :mox.defmock(MockExIRC, for: ExIRC.ClientBehaviour)
    :mox.expect(MockExIRC, :start_link!, fn -> {:ok, mock_client} end)
    :mox.expect(MockExIRC, :add_handler, fn _, _ -> :ok end)
    :mox.expect(MockExIRC, :connect!, fn _, _, _ -> :ok end)

    # Start a test Registry
    start_supervised!({Registry, keys: :unique, name: Xombadill.IrcRegistry})

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
    # Setup a mock HandlerRegistry
    mock_registry = :mox.defmock(MockHandlerRegistry, for: Xombadill.HandlerRegistryBehaviour)

    :mox.expect(MockHandlerRegistry, :handle_message, fn type, message ->
      send(self(), {:handler_registry_received, type, message})
      :ok
    end)

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
