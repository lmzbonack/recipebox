defmodule Myapp.Scraping do
  @cloudflare_endpoint "https://api.cloudflare.com/client/v4/accounts"

  def scrape_recipe_url(url) when is_binary(url) do
    account_id = Application.get_env(:myapp, :cloudflare)[:account_id]
    api_token = Application.get_env(:myapp, :cloudflare)[:api_token]

    if is_nil(account_id) or is_nil(api_token) do
      {:error, :missing_credentials}
    else
      do_scrape(account_id, api_token, url)
    end
  end

  defp do_scrape(account_id, api_token, url) do
    request_body = %{
      url: url,
      prompt:
        "Extract the recipe information from this webpage. Get the recipe name, author, prep time in minutes, cook time in minutes, list of ingredients, step-by-step instructions, AND the source URL of the recipe.",
      response_format: %{
        type: "json_schema",
        schema: %{
          type: "object",
          properties: %{
            name: %{type: "string"},
            author: %{type: "string"},
            prep_time_in_minutes: %{type: "integer"},
            cook_time_in_minutes: %{type: "integer"},
            ingredients: %{type: "array", items: %{type: "string"}},
            instructions: %{type: "array", items: %{type: "string"}},
            external_link: %{type: "string"}
          },
          required: ["name", "ingredients", "instructions"]
        }
      },
      gotoOptions: %{
        waitUntil: "networkidle0"
      }
    }

    endpoint = "#{@cloudflare_endpoint}/#{account_id}/browser-rendering/json"

    headers = [
      {"Authorization", "Bearer #{api_token}"},
      {"Content-Type", "application/json"}
    ]

    case Finch.build(:post, endpoint, headers, Jason.encode!(request_body))
         |> Finch.request(Myapp.Finch, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: body}} ->
        parse_response(body)

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, %{transport_error: reason}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(body) do
    case Jason.decode(body) do
      {:ok, %{"success" => true, "result" => result}} ->
        {:ok, result}

      {:ok, %{"success" => false, "errors" => errors}} ->
        {:error, %{api_errors: errors}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
