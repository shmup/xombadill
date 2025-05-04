# Load support files
Code.require_file("support/behaviours.ex", __DIR__)

# Use a shared test configuration
ExUnit.configure(exclude: [:irc_client, :reload_coordinator])

# Configure Mox explicitly
Application.ensure_all_started(:mox)

# We won't define mocks globally anymore, but in each test file individually

ExUnit.start()
