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
    available_profiles = RouteProfileCatalog.available_profiles

    if available_profiles.empty?
      raise ValidationError.new(details: { profile: ["no profiles are currently available"] })
    end

    unless available_profiles.include?(profile.to_s)
      raise ValidationError.new(details: { profile: ["is not included in the list"] })
    end

    provider_profile = RouteProfileCatalog.provider_profile_for(profile)

    if provider_profile.blank?
      raise ValidationError.new(details: { profile: ["is not configured for the active provider"] })
    end

    @provider.route(profile: provider_profile, points:, options:)
  end
end