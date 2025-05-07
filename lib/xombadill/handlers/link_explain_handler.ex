defmodule Xombadill.Handlers.LinkExplainHandler do
  @moduledoc """
  Handler that recognizes YouTube links in channel messages and fetches their titles.

  Looks for YouTube URLs (various types) in incoming channel messages, fetches the webpage,
  extracts and relays the video title to the channel for context.
  """
  @behaviour Xombadill.HandlerBehaviour
  require Logger

  # YouTube regex patterns for different URL formats
  @youtube_patterns [
    # Standard youtube.com/watch format
    ~r{https?://(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]+)(?:&\S*)?},
    # Short youtu.be format
    ~r{https?://(?:www\.)?youtu\.be/([a-zA-Z0-9_-]+)(?:\?\S*)?},
    # Embed format
    ~r{https?://(?:www\.)?youtube\.com/embed/([a-zA-Z0-9_-]+)(?:\?\S*)?}
  ]

  @impl true
  def handle_message(:channel_message, %{text: text} = _msg) do
    case youtube_extract_video_id(text) do
      nil ->
        :ok

      video_id ->
        video_id
        |> youtube_fetch_title()
        |> case do
          {:ok, title} -> Xombadill.Config.say("YouTube: #{title}")
          {:error, reason} -> Logger.error("Failed to fetch YouTube title: #{reason}")
        end
    end

    :ok
  end

  def handle_message(_type, _message), do: :ok

  @doc """
  Extracts YouTube video ID from various YouTube URL formats.
  Returns the video ID or nil if no match found.
  """
  def youtube_extract_video_id(text) do
    Enum.find_value(@youtube_patterns, fn pattern ->
      case Regex.run(pattern, text) do
        [_full_match, video_id] -> video_id
        _ -> nil
      end
    end)
  end

  @doc """
  Gets the URL for a YouTube video ID.
  """
  def youtube_canonical_url(video_id) do
    "https://www.youtube.com/watch?v=#{video_id}"
  end

  @doc """
  Fetches the title of a YouTube video by its ID.
  """
  def youtube_fetch_title(video_id) do
    url = youtube_canonical_url(video_id)

    case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        html = to_string(body)
        youtube_parse_title(html)

      {:ok, {{_, status, _}, _, _}} ->
        {:error, "HTTP error: #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp youtube_parse_title(html) do
    # Try to extract the title from meta tag first (more reliable)
    case Regex.run(~r{<meta\s+name="title"\s+content="([^"]+)"}, html) do
      [_, title] ->
        {:ok, title}

      nil ->
        # Fall back to og:title
        case Regex.run(~r{<meta\s+property="og:title"\s+content="([^"]+)"}, html) do
          [_, title] ->
            {:ok, title}

          nil ->
            # Fall back to page title as last resort
            case Regex.run(~r{<title>([^<]+)</title>}, html) do
              [_, title] ->
                # Remove " - YouTube" suffix if present
                clean_title = Regex.replace(~r{\s+-\s+YouTube$}, title, "")
                {:ok, clean_title}

              nil ->
                {:error, "Title not found"}
            end
        end
    end
  end
end
