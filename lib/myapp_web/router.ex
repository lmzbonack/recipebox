defmodule MyappWeb.Router do
  use MyappWeb, :router

  import MyappWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyappWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :recipe_owner do
    plug MyappWeb.Plugs.RecipeOwner
  end

  pipeline :sl_owner do
    plug MyappWeb.Plugs.ShoppingListOwner
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyappWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyappWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:myapp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MyappWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MyappWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MyappWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MyappWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MyappWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/recipes", RecipeLive.Index, :index
      live "/recipes/new", RecipeLive.Index, :new
      live "/recipes/:id", RecipeLive.Show, :show
      live "/shopping-lists", ShoppingListsLive.Index, :index
      live "/shopping-lists/new", ShoppingListsLive.Index, :new
    end
  end

  scope "/", MyappWeb do
    pipe_through [:browser, :require_authenticated_user, :recipe_owner]

    live_session :recipe_owner,
      on_mount: [{MyappWeb.UserAuth, :ensure_authenticated}] do
      live "/recipes/:id/edit", RecipeLive.Index, :edit
      live "/recipes/:id/details/edit", RecipeLive.Show, :edit
    end
  end

  scope "/", MyappWeb do
    pipe_through [:browser, :require_authenticated_user, :sl_owner]

    live_session :sl_owner,
      on_mount: [{MyappWeb.UserAuth, :ensure_authenticated}] do
      live "/shopping-lists/:id/edit", ShoppingListsLive.Index, :edit
      live "/shopping-lists/:id", ShoppingListsLive.Show, :show
    end
  end

  scope "/", MyappWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MyappWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
