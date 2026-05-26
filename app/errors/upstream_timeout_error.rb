class UpstreamTimeoutError < RoutingError
  def initialize(provider:)
    super(
      code: "upstream_timeout",
      message: "Routing provider timed out",
      details: { provider: provider },
      status: :gateway_timeout
    )
  end
end