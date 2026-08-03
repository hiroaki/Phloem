require "rails_helper"

RSpec.describe "GET /provider_usage", type: :request do
  around do |example|
    original_api_key = ENV["PHLOEM_API_KEY"]
    configured_api_key.nil? ? ENV.delete("PHLOEM_API_KEY") : ENV["PHLOEM_API_KEY"] = configured_api_key
    example.run
  ensure
    original_api_key.nil? ? ENV.delete("PHLOEM_API_KEY") : ENV["PHLOEM_API_KEY"] = original_api_key
  end

  let(:configured_api_key) { nil }

  it "returns the latest provider usage snapshot" do
    service = instance_double(
      RoutingService,
      provider_usage_snapshot: {
        provider: "graphhopper",
        limit: 500,
        remaining: 471,
        reset_at: "2026-08-03T23:59:59Z"
      }
    )

    allow(RoutingService).to receive(:new).and_return(service)

    get "/provider_usage"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq(
      "provider_usage" => {
        "provider" => "graphhopper",
        "limit" => 500,
        "remaining" => 471,
        "reset_at" => "2026-08-03T23:59:59Z"
      }
    )
  end

  it "returns null when no usage snapshot is available" do
    service = instance_double(RoutingService, provider_usage_snapshot: nil)
    allow(RoutingService).to receive(:new).and_return(service)

    get "/provider_usage"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("provider_usage" => nil)
  end

  context "when API key auth is enabled" do
    let(:configured_api_key) { "test-secret" }

    it "returns unauthorized when API key is missing" do
      get "/provider_usage"

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq(
        "error" => {
          "code" => "authentication_error",
          "message" => "API key is missing or invalid",
          "details" => {}
        }
      )
    end

    it "accepts a valid API key" do
      service = instance_double(RoutingService, provider_usage_snapshot: nil)
      allow(RoutingService).to receive(:new).and_return(service)

      get "/provider_usage", headers: { "Authorization" => "Bearer test-secret" }

      expect(response).to have_http_status(:ok)
    end
  end
end
