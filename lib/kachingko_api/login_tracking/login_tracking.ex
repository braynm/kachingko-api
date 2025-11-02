defmodule KachingkoApi.LoginTracking do
  @moduledoc """
  Public API for the LoginTracking bounded context.
  """

  alias KachingkoApi.LoginTracking.Application.ValueObjects.Authentication
  alias KachingkoApi.LoginTracking.Application.Services.LoginTrackingService

  def track_login(tracking_opts, claims) when is_map(tracking_opts) and is_map(claims) do
    params = Authentication.from_guardian_opts(tracking_opts, claims)

    LoginTrackingService.track_login(params)
  end
end
