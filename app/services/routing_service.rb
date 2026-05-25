class RoutingService
  PROVIDERS = {
    "graphhopper" => GraphHopperAdapter
  }.freeze

  def initialize(provider_key: ENV.fetch("ROUTING_PROVIDER", "graphhopper"))
    provider_class = PROVIDERS.fetch(provider_key) do
      raise UpstreamError.new(
        message: "Unsupported routing provider",
        details: { provider: provider_key },
        status: :internal_server_error
      )
    end

    @provider = provider_class.new
  end

  def route(profile:, points:, options: {})
    @provider.route(profile:, points:, options:)
  end
end