class RoutingService
  PROVIDERS = {
    "graphhopper" => GraphHopperAdapter
  }.freeze

  attr_reader :provider

  def initialize(provider_key: ENV.fetch("ROUTING_PROVIDER", "graphhopper"), provider: nil)
    provider_class = PROVIDERS.fetch(provider_key) do
      raise UpstreamError.new(
        message: "Unsupported routing provider",
        details: { provider: provider_key },
        status: :internal_server_error
      )
    end

    @provider = provider || provider_class.new
  end

  def route(profile:, points:, options: {})
    availability_error = RouteProfileCatalog.availability_error_for(profile)
    unless availability_error.nil?
      raise ValidationError.new(details: { profile: [availability_error] })
    end

    provider_profile = RouteProfileCatalog.provider_profile_for(profile)

    if provider_profile.blank?
      raise ValidationError.new(details: { profile: ["is not configured for the active provider"] })
    end

    @provider.route(profile: provider_profile, points:, options:)
  end

  def provider_usage_snapshot
    ProviderUsageSnapshotStore.read(provider: @provider.provider_name)
  end
end