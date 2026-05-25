class RoutingProvider
  def route(profile:, points:, options: {})
    raise NotImplementedError, "#{self.class.name} must implement #route"
  end

  def match(*_args, **_kwargs)
    raise NotImplementedError, "#{self.class.name} must implement #match"
  end

  def capabilities
    raise NotImplementedError, "#{self.class.name} must implement #capabilities"
  end
end