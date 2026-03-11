defmodule Myapp.Scraping do
  def scrape_recipe_url(url) when is_binary(url) do
    config = Application.get_env(:myapp, :recipe_extractor)

    if is_nil(config) or is_nil(config[:url]) or is_nil(config[:api_key]) do
      {:error, :missing_credentials}
    else
      do_scrape(config[:url], config[:api_key], url)
    end
  end

  defp do_scrape(base_url, api_key, url) do
    endpoint = "#{base_url}extract?key=#{api_key}&url=#{URI.encode(url)}"

    headers = [{"Content-Type", "application/json"}]

    case Finch.build(:get, endpoint, headers)
         |> Finch.request(Myapp.Finch, receive_timeout: 120_000) do
      {:ok, %{status: 200, body: body}} ->
        parse_response(body, url)

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, %{transport_error: reason}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(body, original_url) do
    case Jason.decode(body) do
      {:ok, %{"error" => error}} ->
        {:error, %{api_error: error}}

      {:ok, data} ->
        {:ok, Map.put(data, "external_link", original_url)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
