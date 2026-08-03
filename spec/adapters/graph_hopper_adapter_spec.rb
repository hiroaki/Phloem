require "rails_helper"

RSpec.describe GraphHopperAdapter do
  describe "#route" do
    it "maps a GraphHopper response into the normalized route shape" do
      stub_request(:post, "http://graphhopper.test/route")
        .with(
          body: {
            profile: "car",
            points: [[139.76, 35.68], [139.77, 35.69]],
            instructions: false,
            calc_points: true,
            points_encoded: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(
          status: 200,
          body: {
            paths: [
              {
                distance: 1234.5,
                time: 456700,
                points: {
                  type: "LineString",
                  coordinates: [[139.76, 35.68], [139.77, 35.69]]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      adapter = described_class.new(base_url: "http://graphhopper.test", timeout: 1.0)

      expect(
        adapter.route(
          profile: "car",
          points: [
            { lat: 35.68, lon: 139.76 },
            { lat: 35.69, lon: 139.77 }
          ],
          options: {}
        )
      ).to eq(
        provider: "graphhopper",
        geometry: {
          "type" => "LineString",
          "coordinates" => [[139.76, 35.68], [139.77, 35.69]]
        },
        distance_meters: 1234.5,
        duration_seconds: 456.7,
        warnings: []
      )
    end

    it "raises a timeout error when the provider times out" do
      stub_request(:post, "http://graphhopper.test/route").to_timeout

      adapter = described_class.new(base_url: "http://graphhopper.test", timeout: 1.0)

      expect do
        adapter.route(
          profile: "car",
          points: [
            { lat: 35.68, lon: 139.76 },
            { lat: 35.69, lon: 139.77 }
          ],
          options: {}
        )
      end.to raise_error(UpstreamTimeoutError)
    end

    it "disables CH for profiles that are not preprocessed with CH" do
      stub_request(:post, "http://graphhopper.test/route")
        .with(
          body: {
            profile: "bike",
            points: [[139.76, 35.68], [139.77, 35.69]],
            instructions: false,
            calc_points: true,
            points_encoded: false,
            "ch.disable": true
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(
          status: 200,
          body: {
            paths: [
              {
                distance: 1234.5,
                time: 456700,
                points: {
                  type: "LineString",
                  coordinates: [[139.76, 35.68], [139.77, 35.69]]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      adapter = described_class.new(base_url: "http://graphhopper.test", timeout: 1.0)

      expect(
        adapter.route(
          profile: "bike",
          points: [
            { lat: 35.68, lon: 139.76 },
            { lat: 35.69, lon: 139.77 }
          ],
          options: {}
        )
      ).to include(provider: "graphhopper")
    end

    it "keeps requests compatible with restricted plans" do
      stub_request(:post, "http://graphhopper.test/route")
        .with(
          body: {
            profile: "foot",
            points: [[139.76, 35.68], [139.77, 35.69]],
            instructions: false,
            calc_points: true,
            points_encoded: false
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(
          status: 200,
          body: {
            paths: [
              {
                distance: 1234.5,
                time: 456700,
                points: {
                  type: "LineString",
                  coordinates: [[139.76, 35.68], [139.77, 35.69]]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      adapter = described_class.new(
        base_url: "http://graphhopper.test",
        timeout: 1.0,
        restricted_plan: true
      )

      expect(
        adapter.route(
          profile: "foot",
          points: [
            { lat: 35.68, lon: 139.76 },
            { lat: 35.69, lon: 139.77 }
          ],
          options: {}
        )
      ).to include(provider: "graphhopper")
    end

    it "caches rate-limit headers as the latest provider usage snapshot" do
      stub_request(:post, "http://graphhopper.test/route")
        .to_return(
          status: 200,
          body: {
            paths: [
              {
                distance: 1234.5,
                time: 456700,
                points: {
                  type: "LineString",
                  coordinates: [[139.76, 35.68], [139.77, 35.69]]
                }
              }
            ]
          }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-RateLimit-Limit" => "500",
            "X-RateLimit-Remaining" => "472",
            "X-RateLimit-Reset" => "21380",
            "X-RateLimit-Credits" => "1"
          }
        )

      expect(ProviderUsageSnapshotStore).to receive(:write).with(
        provider: "graphhopper",
        snapshot: {
          limit: 500,
          remaining: 472,
          reset_seconds: 21380,
          credits: 1
        }
      )

      adapter = described_class.new(base_url: "http://graphhopper.test", timeout: 1.0)

      adapter.route(
        profile: "car",
        points: [
          { lat: 35.68, lon: 139.76 },
          { lat: 35.69, lon: 139.77 }
        ],
        options: {}
      )
    end
  end
end