class RouteResponseSerializer
  def initialize(route)
    @route = route
  end

  def as_json(*)
    {
      route: {
        geometry: @route.fetch(:geometry),
        distance_meters: @route.fetch(:distance_meters),
        duration_seconds: @route.fetch(:duration_seconds),
        provider: @route.fetch(:provider),
        warnings: Array(@route[:warnings])
      }
    }
  end
end