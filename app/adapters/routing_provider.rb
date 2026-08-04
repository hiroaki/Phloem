class RoutingProvider
  def route(profile:, points:, options: {})
    raise NotImplementedError, "#{self.class.name} must implement #route"
  end

  def provider_name
    self.class.const_get(:PROVIDER_NAME)
  rescue NameError
    self.class.name.underscore
  end

  def usage_snapshot_from_response(_response)
    nil
  end

  def match(*_args, **_kwargs)
    raise NotImplementedError, "#{self.class.name} must implement #match"
  end

  def capabilities
    raise NotImplementedError, "#{self.class.name} must implement #capabilities"
  end
end