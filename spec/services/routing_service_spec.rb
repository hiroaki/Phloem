require "rails_helper"

RSpec.describe RoutingService do
  around do |example|
    original_profiles = ENV["PHLOEM_ROUTE_PROFILES"]
    original_map = ENV["PHLOEM_PROFILE_MAP"]
    RouteProfileCatalog.reset!
    ENV.delete("PHLOEM_ROUTE_PROFILES")
    ENV.delete("PHLOEM_PROFILE_MAP")
    example.run
  ensure
    original_profiles.nil? ? ENV.delete("PHLOEM_ROUTE_PROFILES") : ENV["PHLOEM_ROUTE_PROFILES"] = original_profiles
    original_map.nil? ? ENV.delete("PHLOEM_PROFILE_MAP") : ENV["PHLOEM_PROFILE_MAP"] = original_map
    RouteProfileCatalog.reset!
  end

  describe "#route" do
    it "maps abstract profile names to provider profiles" do
      ENV["PHLOEM_PROFILE_MAP"] = { "car" => "auto" }.to_json
      RouteProfileCatalog.reset!

      provider = instance_double(GraphHopperAdapter)
      allow(provider).to receive(:route).and_return(provider: "graphhopper")

      service = described_class.new(provider: provider)

      service.route(
        profile: "car",
        points: [{ lat: 1.0, lon: 2.0 }, { lat: 1.1, lon: 2.1 }],
        options: {}
      )

      expect(provider).to have_received(:route).with(
        profile: "auto",
        points: [{ lat: 1.0, lon: 2.0 }, { lat: 1.1, lon: 2.1 }],
        options: {}
      )
    end

    it "raises a validation error for unknown abstract profiles" do
      ENV["PHLOEM_ROUTE_PROFILES"] = "car"
      RouteProfileCatalog.reset!

      provider = instance_double(GraphHopperAdapter)
      service = described_class.new(provider: provider)

      expect do
        service.route(
          profile: "train",
          points: [{ lat: 1.0, lon: 2.0 }, { lat: 1.1, lon: 2.1 }],
          options: {}
        )
      end.to raise_error(ValidationError, "Request validation failed")
    end

    it "raises a validation error when no profiles are currently available" do
      RouteProfileCatalog.apply_probe_result!(available_profiles: [], failures: { "car" => "upstream_error" })

      provider = instance_double(GraphHopperAdapter)
      service = described_class.new(provider: provider)

      expect do
        service.route(
          profile: "car",
          points: [{ lat: 1.0, lon: 2.0 }, { lat: 1.1, lon: 2.1 }],
          options: {}
        )
      end.to raise_error(ValidationError, "Request validation failed")
    end

    it "raises a validation error when profile is excluded from available set" do
      RouteProfileCatalog.apply_probe_result!(available_profiles: ["car"], failures: { "bike" => "upstream_error" })

      provider = instance_double(GraphHopperAdapter)
      service = described_class.new(provider: provider)

      expect do
        service.route(
          profile: "bike",
          points: [{ lat: 1.0, lon: 2.0 }, { lat: 1.1, lon: 2.1 }],
          options: {}
        )
      end.to raise_error(ValidationError, "Request validation failed")
    end
  end

  describe "#provider_usage_snapshot" do
    it "reads usage snapshot for the active provider" do
      provider = instance_double(GraphHopperAdapter, provider_name: "graphhopper")
      service = described_class.new(provider: provider)

      expect(ProviderUsageSnapshotStore).to receive(:read)
        .with(provider: "graphhopper")
        .and_return({ provider: "graphhopper", snapshot: { remaining: 10 } })

      expect(service.provider_usage_snapshot).to eq(
        provider: "graphhopper",
        snapshot: { remaining: 10 }
      )
    end
  end
end
