defmodule KachingkoApiWeb.Router do
  use KachingkoApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KachingkoApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KachingkoApiWeb do
    pipe_through :browser
  end

  pipeline :guardian_auth do
    plug Guardian.Plug.Pipeline,
      module: KachingkoApiWeb.Guardian,
      error_handler: KachingkoApiWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  pipeline :guardian_validate_session do
    plug KachingkoApiWeb.Plugs.ValidateGuardianSession
  end

  scope "/api", KachingkoApiWeb do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  scope "/api", KachingkoApiWeb do
    pipe_through [:api, :guardian_auth]

    get "/auth/me", AuthController, :me
  end

  scope "/api", KachingkoApiWeb do
    pipe_through [:api, :guardian_auth, :guardian_validate_session]

    get "/auth/test", AuthController, :test
    get "/auth/logout", AuthController, :logout

    get "/statements/cards", StatementsController, :get_cards
    post "/statements/new-card", StatementsController, :new_card

    post "/statements/upload", StatementsController, :upload
    get "/statements/txns", StatementsController, :list_txns
    get "/statements/month-summary-spent", StatementsController, :month_summay_spent

    get "/charts", ChartsController, :fetch_user_charts
  end

  # Other scopes may use custom stacks.
  # scope "/api", KachingkoApiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kachingko_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KachingkoApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
