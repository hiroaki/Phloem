class UpstreamError < RoutingError
  def initialize(message: "Routing provider request failed", details: {}, status: :bad_gateway)
    super(code: "upstream_error", message: message, details: details, status: status)
  end
end