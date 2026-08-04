require "rails_helper"

RSpec.describe RouteRequest do
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

  let(:points) { [{ lat: 35.68, lon: 139.76 }, { lat: 35.69, lon: 139.77 }] }

  it "accepts default profiles when profile config is not set" do
    request = described_class.new(profile: "car", points:, options: {})

    expect(request).to be_valid
  end

  it "rejects requests when no profile is available after probing" do
    RouteProfileCatalog.apply_probe_result!(available_profiles: [], failures: { "car" => "upstream_error" })

    request = described_class.new(profile: "car", points:, options: {})

    expect(request).not_to be_valid
    expect(request.error_details).to eq(profile: ["no profiles are currently available"])
  end
end
