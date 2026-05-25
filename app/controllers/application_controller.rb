class ApplicationController < ActionController::API
	rescue_from RoutingError, with: :render_routing_error

	private

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
