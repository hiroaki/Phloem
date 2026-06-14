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
  end
end
