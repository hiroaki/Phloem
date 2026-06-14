class RouteProfileProbe
  DEFAULT_PROBE_POINTS = [
    { lat: 35.68, lon: 139.76 },
    { lat: 35.69, lon: 139.77 }
  ].freeze

  class << self
    def run!(provider: nil, logger: Rails.logger)
      provider_instance = provider || RoutingService.new.provider
      available_profiles = []
      failures = {}

      RouteProfileCatalog.configured_profiles.each do |abstract_profile|
        provider_profile = RouteProfileCatalog.provider_profile_for(abstract_profile)

        if provider_profile.blank?
          failures[abstract_profile] = "profile mapping is missing"
          next
        end

        begin
          provider_instance.route(profile: provider_profile, points: probe_points, options: {})
          available_profiles << abstract_profile
        rescue RoutingError => error
          failures[abstract_profile] = "#{error.code}: #{error.message}"
        rescue StandardError => error
          failures[abstract_profile] = "#{error.class}: #{error.message}"
        end
      end

      RouteProfileCatalog.apply_probe_result!(available_profiles:, failures:)
      logger&.info(
        "Route profile probe finished: available=#{available_profiles.size}, unavailable=#{failures.size}"
      )

      RouteProfileCatalog.available_profiles
    end

    private

    def probe_points
      raw = ENV["PHLOEM_PROFILE_PROBE_POINTS"].to_s
      return DEFAULT_PROBE_POINTS if raw.strip.empty?

      parsed_points = raw.split(";").map do |pair|
        lat_str, lon_str = pair.split(",", 2).map { |value| value.to_s.strip }

        {
          lat: Float(lat_str),
          lon: Float(lon_str)
        }
      end

      return DEFAULT_PROBE_POINTS unless parsed_points.size >= 2

      parsed_points
    rescue ArgumentError, TypeError
      DEFAULT_PROBE_POINTS
    end
  end
end
