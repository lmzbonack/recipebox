defmodule MyappWeb.RecipeLive.Cooking do
  use MyappWeb, :live_view

  alias Myapp.Recipes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recipe = Recipes.get_recipe!(id)
    scaled = scale_ingredients(recipe.ingredients, 1)

    {:ok,
     assign(socket,
       recipe: recipe,
       page_title: "Cooking: #{recipe.name}",
       scale: 1,
       scaled_ingredients: scaled
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    scale = Map.get(params, "scale", "1") |> String.to_integer() |> clamp_scale(1, 4)
    scaled = scale_ingredients(socket.assigns.recipe.ingredients, scale)
    {:noreply, assign(socket, scale: scale, scaled_ingredients: scaled)}
  end

  @impl true
  def handle_event("set_scale", %{"scale" => scale}, socket) do
    scale = String.to_integer(scale) |> clamp_scale(1, 4)

    {:noreply,
     push_patch(socket, to: ~p"/recipes/#{socket.assigns.recipe.id}/cook?scale=#{scale}")}
  end

  defp clamp_scale(scale, min, max) do
    scale |> max(min) |> min(max)
  end

  def scale_ingredients(ingredients, scale) do
    Enum.map(ingredients, &parse_ingredient(&1, scale))
  end

  defp parse_ingredient(ingredient, scale) do
    case extract_quantity(ingredient) do
      {quantity, rest} ->
        scaled = quantity * scale
        "#{format_quantity(scaled)}#{rest}"

      nil ->
        ingredient
    end
  end

  defp extract_quantity(ingredient) do
    case Regex.run(~r/^([\d\s\/\.\,]+)\s*(.*)/, ingredient, capture: :all_but_first) do
      [quantity_str, rest] ->
        case parse_fraction(quantity_str) do
          nil -> nil
          quantity -> {quantity, " " <> rest}
        end

      nil ->
        nil
    end
  end

  defp parse_fraction(str) do
    str = String.trim(str)

    cond do
      Regex.match?(~r/^\d+\/\d+$/, str) ->
        [num, den] = String.split(str, "/") |> Enum.map(&String.to_integer/1)
        num / den

      Regex.match?(~r/^\d+\s+\d+\/\d+$/, str) ->
        [whole, fraction] = String.split(str, " ")
        [num, den] = String.split(fraction, "/") |> Enum.map(&String.to_integer/1)
        String.to_integer(whole) + num / den

      Regex.match?(~r/^\d+$/, str) ->
        String.to_integer(str)

      Regex.match?(~r/^\d+\.?\d*$/, str) ->
        case Float.parse(str) do
          {num, ""} -> num
          _ -> nil
        end

      Regex.match?(~r/^0\.\d+$/, str) ->
        case Float.parse(str) do
          {num, ""} -> num
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp format_quantity(num) when is_float(num) do
    int_part = trunc(num)
    frac_part = num - int_part

    fraction_str =
      cond do
        abs(frac_part - 0.25) < 0.01 -> "1/4"
        abs(frac_part - 0.33) < 0.02 -> "1/3"
        abs(frac_part - 0.5) < 0.01 -> "1/2"
        abs(frac_part - 0.66) < 0.02 -> "2/3"
        abs(frac_part - 0.75) < 0.01 -> "3/4"
        true -> nil
      end

    cond do
      int_part == 0 and fraction_str -> fraction_str
      fraction_str -> "#{int_part} #{fraction_str}"
      true -> "#{num}"
    end
  end

  defp format_quantity(num) when is_integer(num), do: Integer.to_string(num)

  @impl true
  def render(assigns) do
    ~H"""
    <div id="cooking-view" class="min-h-screen bg-zinc-50 pb-20" phx-hook="WakeLock">
      <div class="max-w-md mx-auto px-4 py-6">
        <.link
          navigate={~p"/recipes/#{@recipe.id}"}
          class="text-blue-600 hover:underline text-lg mb-4 inline-block"
        >
          ← Back to recipe
        </.link>

        <h1 class="text-2xl font-bold text-zinc-800 mb-2">
          <a
            href={@recipe.external_link}
            target="_blank"
            rel="noopener noreferrer"
            class="text-blue-600 hover:underline"
          >
            {@recipe.name}
          </a>
        </h1>
        <p class="text-zinc-600 mb-6">By: {@recipe.author}</p>

        <div class="flex gap-2 mb-8">
          <%= for s <- [1, 2, 3, 4] do %>
            <button
              phx-click="set_scale"
              phx-value-scale={s}
              class={[
                "flex-1 py-3 px-4 rounded-lg font-semibold text-lg transition-colors",
                if(@scale == s,
                  do: "bg-zinc-800 text-white",
                  else: "bg-white text-zinc-700 border-2 border-zinc-300 hover:border-zinc-400"
                )
              ]}
            >
              {s}x
            </button>
          <% end %>
        </div>

        <div class="mb-8">
          <h2 class="text-xl font-semibold text-zinc-800 mb-4">Ingredients</h2>
          <ul class="space-y-3">
            <%= for ingredient <- @scaled_ingredients do %>
              <li class="text-lg text-zinc-700 leading-relaxed">{ingredient}</li>
            <% end %>
          </ul>
        </div>

        <div>
          <h2 class="text-xl font-semibold text-zinc-800 mb-4">Instructions</h2>
          <ol class="space-y-6">
            <%= for {instruction, index} <- Enum.with_index(@recipe.instructions, 1) do %>
              <li class="text-lg text-zinc-700 leading-relaxed">
                <span class="font-semibold text-zinc-900">{index}.</span> {instruction}
              </li>
            <% end %>
          </ol>
        </div>
      </div>
    </div>
    """
  end
end
