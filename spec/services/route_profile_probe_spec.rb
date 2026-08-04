require "rails_helper"

RSpec.describe RouteProfileProbe do
  around do |example|
    original_profiles = ENV["PHLOEM_ROUTE_PROFILES"]
    original_map = ENV["PHLOEM_PROFILE_MAP"]
    original_probe_points = ENV["PHLOEM_PROFILE_PROBE_POINTS"]

    RouteProfileCatalog.reset!
    ENV.delete("PHLOEM_ROUTE_PROFILES")
    ENV.delete("PHLOEM_PROFILE_MAP")
    ENV.delete("PHLOEM_PROFILE_PROBE_POINTS")

    example.run
  ensure
    original_profiles.nil? ? ENV.delete("PHLOEM_ROUTE_PROFILES") : ENV["PHLOEM_ROUTE_PROFILES"] = original_profiles
    original_map.nil? ? ENV.delete("PHLOEM_PROFILE_MAP") : ENV["PHLOEM_PROFILE_MAP"] = original_map
    original_probe_points.nil? ? ENV.delete("PHLOEM_PROFILE_PROBE_POINTS") : ENV["PHLOEM_PROFILE_PROBE_POINTS"] = original_probe_points
    RouteProfileCatalog.reset!
  end

  it "keeps only profiles that succeed during probing" do
    ENV["PHLOEM_ROUTE_PROFILES"] = "car,bike,foot"
    RouteProfileCatalog.reset!

    provider = instance_double(GraphHopperAdapter)
    allow(provider).to receive(:route).with(hash_including(profile: "car")).and_return(provider: "graphhopper")
    allow(provider).to receive(:route).with(hash_including(profile: "bike")).and_raise(
      UpstreamError.new(message: "profile unavailable")
    )
    allow(provider).to receive(:route).with(hash_including(profile: "foot")).and_return(provider: "graphhopper")

    logger = instance_double(Logger, info: nil, warn: nil)

    described_class.run!(provider:, logger: logger)

    expect(RouteProfileCatalog.available_profiles).to eq(%w[car foot])
    expect(RouteProfileCatalog.unavailable_profiles.keys).to contain_exactly("bike")
    expect(logger).to have_received(:info).with(
      "Route profile probe finished: available=2, unavailable=1"
    )
    expect(logger).to have_received(:info).with(
      "Route profile probe success: profiles=car,foot"
    )
    expect(logger).to have_received(:warn).with(
      "Route profile probe failure: profile=bike, reason=upstream_error: profile unavailable"
    )
  end

  it "marks profile as unavailable when mapping is missing" do
    ENV["PHLOEM_ROUTE_PROFILES"] = "car"
    ENV["PHLOEM_PROFILE_MAP"] = { "car" => "" }.to_json
    RouteProfileCatalog.reset!

    provider = instance_double(GraphHopperAdapter)

    described_class.run!(provider:, logger: nil)

    expect(RouteProfileCatalog.available_profiles).to eq([])
    expect(RouteProfileCatalog.unavailable_profiles).to eq("car" => "profile mapping is missing")
  end

  it "falls back to default probe points when probe point env is invalid" do
    ENV["PHLOEM_PROFILE_PROBE_POINTS"] = "invalid"

    provider = instance_double(GraphHopperAdapter)
    allow(provider).to receive(:route).with(
      hash_including(points: [{ lat: 35.68, lon: 139.76 }, { lat: 35.69, lon: 139.77 }])
    ).and_return(provider: "graphhopper")

    described_class.run!(provider:, logger: nil)

    expect(RouteProfileCatalog.available_profiles).to include("car")
  end
end
