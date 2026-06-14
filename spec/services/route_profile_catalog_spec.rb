require "rails_helper"

RSpec.describe RouteProfileCatalog do
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

  it "uses car bike foot by default when no profile env vars are set" do
    expect(described_class.configured_profiles).to eq(%w[car bike foot])
    expect(described_class.provider_profile_for("car")).to eq("car")
    expect(described_class.provider_profile_for("bike")).to eq("bike")
    expect(described_class.provider_profile_for("foot")).to eq("foot")
  end

  it "supports custom profile lists and provider profile mappings" do
    ENV["PHLOEM_ROUTE_PROFILES"] = "car,bike,walk"
    ENV["PHLOEM_PROFILE_MAP"] = { "car" => "auto", "bike" => "roadbike", "walk" => "pedestrian" }.to_json
    described_class.reset!

    expect(described_class.configured_profiles).to eq(%w[car bike walk])
    expect(described_class.provider_profile_for("car")).to eq("auto")
    expect(described_class.provider_profile_for("bike")).to eq("roadbike")
    expect(described_class.provider_profile_for("walk")).to eq("pedestrian")
  end

  it "stores available and unavailable profiles after probe filtering" do
    described_class.apply_probe_result!(
      available_profiles: %w[car bike],
      failures: { "foot" => "upstream_error: failed" }
    )

    expect(described_class.available_profiles).to eq(%w[car bike])
    expect(described_class.unavailable_profiles).to eq("foot" => "upstream_error: failed")
  end
end
