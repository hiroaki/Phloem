class ProviderUsageController < ApplicationController
  before_action :authenticate_with_api_key!

  def show
    snapshot = RoutingService.new.provider_usage_snapshot

    render json: { provider_usage: snapshot }
  end
end
