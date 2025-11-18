defmodule KachingkoApiWeb.Plugs.TwoFactorPipeline do
  @moduledoc """
  Pipeline that allows 2FA pending tokens.
  Used only for 2FA verification endpoints.
  """

  use Guardian.Plug.Pipeline,
    otp_app: :kachingko_api,
    module: KachingkoApi.Guardian,
    error_handler: KachingkoApiWeb.AuthController

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
