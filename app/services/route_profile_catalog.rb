require "json"

class RouteProfileCatalog
  DEFAULT_PROFILES = %w[car bike foot].freeze

  class << self
    def configured_profiles
      @configured_profiles ||= parsed_profile_list
    end

    def available_profiles
      @available_profiles ||= configured_profiles.dup
    end

    def provider_profile_for(abstract_profile)
      provider_profile_map[abstract_profile.to_s]
    end

    def provider_profile_map
      @provider_profile_map ||= parsed_profile_map
    end

    def unavailable_profiles
      @unavailable_profiles ||= {}
    end

    def use_configured_profiles!
      failures = {}

      @available_profiles = configured_profiles.filter_map do |abstract_profile|
        provider_profile = provider_profile_for(abstract_profile)
        if provider_profile.present?
          abstract_profile
        else
          failures[abstract_profile] = "profile mapping is missing"
          nil
        end
      end

      @unavailable_profiles = failures
    end

    def apply_probe_result!(available_profiles:, failures:)
      @available_profiles = Array(available_profiles).map(&:to_s).uniq
      @unavailable_profiles = failures.transform_keys(&:to_s)
    end

    def reset!
      @configured_profiles = nil
      @provider_profile_map = nil
      @available_profiles = nil
      @unavailable_profiles = nil
    end

    private

    def parsed_profile_list
      raw_profiles = ENV["PHLOEM_ROUTE_PROFILES"].to_s
      return DEFAULT_PROFILES.dup if raw_profiles.strip.empty?

      parsed = raw_profiles.split(",").map { |profile| profile.strip }.reject(&:empty?).uniq
      parsed.empty? ? DEFAULT_PROFILES.dup : parsed
    end

    def parsed_profile_map
      identity_map = configured_profiles.index_with { |profile| profile }
      raw_map = ENV["PHLOEM_PROFILE_MAP"].to_s
      return identity_map if raw_map.strip.empty?

      parsed_map = JSON.parse(raw_map)
      return identity_map unless parsed_map.is_a?(Hash)

      identity_map.merge(parsed_map.transform_keys(&:to_s).transform_values(&:to_s))
    rescue JSON::ParserError
      identity_map
    end
  end
end
