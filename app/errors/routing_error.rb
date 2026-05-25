class RoutingError < StandardError
  attr_reader :code, :details, :status

  def initialize(code:, message:, details: {}, status: :bad_gateway)
    super(message)
    @code = code
    @details = details
    @status = status
  end
end

class ValidationError < RoutingError
  def initialize(message: "Request validation failed", details: {})
    super(code: "validation_error", message: message, details: details, status: :unprocessable_content)
  end
end

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

class UpstreamError < RoutingError
  def initialize(message: "Routing provider request failed", details: {}, status: :bad_gateway)
    super(code: "upstream_error", message: message, details: details, status: status)
  end
end