class ApplicationController < ActionController::API
	rescue_from RoutingError, with: :render_routing_error

	private

	def authenticate_with_api_key!
		return if configured_api_key.blank?
		raise AuthenticationError unless valid_api_key?(request_api_key)
	end

	def configured_api_key
		ENV["PHLOEM_API_KEY"]
	end

	def request_api_key
		bearer_token.presence || request.headers["X-API-Key"].presence
	end

	def bearer_token
		auth_header = request.authorization.to_s
		prefix = "Bearer "
		return unless auth_header.start_with?(prefix)

		auth_header.delete_prefix(prefix)
	end

	def valid_api_key?(candidate)
		return false if candidate.blank?
		return false unless candidate.bytesize == configured_api_key.bytesize

		ActiveSupport::SecurityUtils.secure_compare(candidate, configured_api_key)
	end

	def render_routing_error(error)
		render json: {
			error: {
				code: error.code,
				message: error.message,
				details: error.details
			}
		}, status: error.status
	end
end
