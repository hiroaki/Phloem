class AuthenticationError < RoutingError
  def initialize(message: "API key is missing or invalid", details: {})
    super(code: "authentication_error", message: message, details: details, status: :unauthorized)
  end
end