class RoutingError < StandardError
  attr_reader :code, :details, :status

  def initialize(code:, message:, details: {}, status: :bad_gateway)
    super(message)
    @code = code
    @details = details
    @status = status
  end
end