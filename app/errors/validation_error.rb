class ValidationError < RoutingError
  def initialize(message: "Request validation failed", details: {})
    super(code: "validation_error", message: message, details: details, status: :unprocessable_content)
  end
end