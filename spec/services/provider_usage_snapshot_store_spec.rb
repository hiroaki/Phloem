require "rails_helper"

RSpec.describe ProviderUsageSnapshotStore do
  describe ".write" do
    let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(described_class).to receive(:cache_backend).and_return(cache_store)
    end

    it "normalizes graphhopper rate-limit data before writing to cache" do
      captured_at = Time.utc(2026, 8, 3, 18, 3, 39)
      allow(Time).to receive(:current).and_return(captured_at)

      described_class.write(
        provider: "graphhopper",
        snapshot: {
          limit: 500,
          remaining: 472,
          credits: 1,
          reset_seconds: 21380
        }
      )

      expect(cache_store.read("provider_usage_snapshot:graphhopper")).to eq(
        provider: "graphhopper",
        limit: 500,
        remaining: 471,
        reset_at: "2026-08-03T23:59:59Z",
        captured_at: "2026-08-03T18:03:39Z"
      )

    end

    it "writes remaining as-is when credits is missing" do
      captured_at = Time.utc(2026, 8, 3, 18, 3, 39)
      allow(Time).to receive(:current).and_return(captured_at)

      described_class.write(
        provider: "graphhopper",
        snapshot: {
          limit: 500,
          remaining: 472,
          reset_seconds: 21380
        }
      )

      expect(cache_store.read("provider_usage_snapshot:graphhopper")).to eq(
        provider: "graphhopper",
        limit: 500,
        remaining: 472,
        reset_at: "2026-08-03T23:59:59Z",
        captured_at: "2026-08-03T18:03:39Z"
      )

    end

    it "does not write when snapshot has no usable values" do
      described_class.write(provider: "graphhopper", snapshot: {})

      expect(cache_store.read("provider_usage_snapshot:graphhopper")).to be_nil
    end
  end
end
