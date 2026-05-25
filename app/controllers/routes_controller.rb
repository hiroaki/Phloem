class RoutesController < ApplicationController
  def create
    route_request = RouteRequest.new(request.request_parameters)

    raise ValidationError.new(details: route_request.error_details) unless route_request.valid?

    route = RoutingService.new.route(**route_request.to_h)

    render json: RouteResponseSerializer.new(route).as_json
  end
end