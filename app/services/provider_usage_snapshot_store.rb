class ProviderUsageSnapshotStore
  CACHE_KEY_PREFIX = "provider_usage_snapshot".freeze

  class << self
    def write(provider:, snapshot:)
      return if provider.to_s.empty?

      normalized = normalize_snapshot(snapshot, captured_at: Time.current)
      return if normalized.nil?

      cache_backend.write(cache_key(provider), normalized.merge(provider: provider))
    end

    def read(provider:)
      return nil if provider.to_s.empty?

      cache_backend.read(cache_key(provider))
    end

    private

    def normalize_snapshot(snapshot, captured_at:)
      return nil unless snapshot.is_a?(Hash)

      limit = to_integer(snapshot[:limit] || snapshot["limit"])
      remaining = effective_remaining(snapshot)
      reset_at = normalize_reset_at(snapshot, captured_at:)

      normalized = {
        limit: limit,
        remaining: remaining,
        reset_at: reset_at
      }.compact

      normalized.empty? ? nil : normalized
    end

    def effective_remaining(snapshot)
      remaining = to_integer(snapshot[:remaining] || snapshot["remaining"])
      return nil if remaining.nil?

      credits = to_integer(snapshot[:credits] || snapshot["credits"]) || 0
      [remaining - credits, 0].max
    end

    def normalize_reset_at(snapshot, captured_at:)
      reset_at = snapshot[:reset_at] || snapshot["reset_at"]
      return normalize_time(reset_at) unless reset_at.nil?

      reset_seconds = to_integer(snapshot[:reset_seconds] || snapshot["reset_seconds"])
      return nil if reset_seconds.nil?

      (captured_at.utc + reset_seconds).iso8601
    end

    def normalize_time(value)
      return value.utc.iso8601 if value.respond_to?(:utc)

      parsed = Time.iso8601(value.to_s)
      parsed.utc.iso8601
    rescue ArgumentError, TypeError
      nil
    end

    def to_integer(value)
      return value if value.is_a?(Integer)

      Integer(value, 10)
    rescue ArgumentError, TypeError
      nil
    end

    def cache_key(provider)
      "#{CACHE_KEY_PREFIX}:#{provider}"
    end

    def cache_backend
      Rails.cache
    end
  end
end
