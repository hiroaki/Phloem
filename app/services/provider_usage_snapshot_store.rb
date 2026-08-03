class ProviderUsageSnapshotStore
  CACHE_KEY_PREFIX = "provider_usage_snapshot".freeze

  class << self
    def write(provider:, snapshot:)
      return if provider.to_s.empty?

      Rails.cache.write(cache_key(provider), {
        provider: provider,
        snapshot: snapshot,
        captured_at: Time.current.iso8601
      })
    end

    def read(provider:)
      return nil if provider.to_s.empty?

      Rails.cache.read(cache_key(provider))
    end

    private

    def cache_key(provider)
      "#{CACHE_KEY_PREFIX}:#{provider}"
    end
  end
end
