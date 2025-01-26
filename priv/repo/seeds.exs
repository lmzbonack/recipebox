# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Myapp.Repo
alias Myapp.Accounts
alias Myapp.Recipes.Recipe
alias Myapp.ShoppingLists
alias Myapp.Accounts.User

# Clear existing data
Repo.delete_all(Recipe)
Repo.delete_all(User)

# Create a user using proper registration
{:ok, user} =
  Accounts.register_user(%{
    email: "chef@example.com",
    # Must be at least 12 characters based on your validation
    password: "password123456"
  })

# Create two recipes
recipes = [
  %{
    name: "Classic Chocolate Chip Cookies",
    author: "Chef John",
    prep_time_in_minutes: 20,
    cook_time_in_minutes: 12,
    ingredients: [
      "2 1/4 cups all-purpose flour",
      "1 cup butter, softened",
      "3/4 cup sugar",
      "3/4 cup brown sugar",
      "2 large eggs",
      "1 tsp vanilla extract",
      "1 tsp baking soda",
      "1/2 tsp salt",
      "2 cups chocolate chips"
    ],
    instructions: [
      "Preheat oven to 375°F (190°C)",
      "Cream together butter and sugars",
      "Beat in eggs and vanilla",
      "Mix in dry ingredients",
      "Stir in chocolate chips",
      "Drop by rounded tablespoons onto ungreased baking sheets",
      "Bake for 10 to 12 minutes or until golden brown"
    ],
    created_by_id: user.id
  },
  %{
    name: "Simple Spaghetti Carbonara",
    author: "Chef Maria",
    prep_time_in_minutes: 10,
    cook_time_in_minutes: 20,
    ingredients: [
      "1 pound spaghetti",
      "4 large eggs",
      "1 cup grated Pecorino Romano",
      "1 cup grated Parmigiano Reggiano",
      "4 oz pancetta or guanciale, diced",
      "2 cloves garlic, minced",
      "Black pepper to taste"
    ],
    instructions: [
      "Bring a large pot of salted water to boil",
      "Cook pasta according to package directions",
      "While pasta cooks, crisp pancetta in a large pan",
      "Whisk eggs and cheese in a bowl",
      "Toss hot pasta with pancetta",
      "Stir in egg mixture quickly",
      "Season with black pepper and serve immediately"
    ],
    created_by_id: user.id
  }
]

[cookie_recipe, _carbonara_recipe] =
  Enum.map(recipes, fn recipe ->
    Recipe.changeset(%Recipe{}, recipe)
    |> Repo.insert!()
  end)

# Create a shopping list for the cookies
{:ok, shopping_list} =
  ShoppingLists.create_shopping_list(
    %{
      name: "Cookie Shopping List",
      ingredients: [
        "Extra Chocolate chips for eating"
      ]
    },
    user
  )

# Add the cookie recipe to the shopping list
ShoppingLists.add_recipe_to_shopping_list(shopping_list, cookie_recipe)

IO.puts("Seed data inserted successfully!")
