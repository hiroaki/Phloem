require "rails_helper"

RSpec.describe "POST /route", type: :request do
  let(:valid_params) do
    {
      profile: "car",
      points: [
        { lat: 35.68, lon: 139.76 },
        { lat: 35.69, lon: 139.77 }
      ],
      options: {}
    }
  end

  it "returns a normalized route payload" do
    service = instance_double(
      RoutingService,
      route: {
        geometry: {
          "type" => "LineString",
          "coordinates" => [[139.76, 35.68], [139.77, 35.69]]
        },
        distance_meters: 1234.5,
        duration_seconds: 456.7,
        provider: "graphhopper",
        warnings: []
      }
    )

    allow(RoutingService).to receive(:new).and_return(service)

    post "/route", params: valid_params, as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq(
      "route" => {
        "geometry" => {
          "type" => "LineString",
          "coordinates" => [[139.76, 35.68], [139.77, 35.69]]
        },
        "distance_meters" => 1234.5,
        "duration_seconds" => 456.7,
        "provider" => "graphhopper",
        "warnings" => []
      }
    )
  end

  it "returns a validation error for an invalid payload" do
    post "/route", params: {
      profile: "car",
      points: [{ lat: 35.68, lon: 139.76 }]
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to eq(
      "error" => {
        "code" => "validation_error",
        "message" => "Request validation failed",
        "details" => {
          "points" => ["must contain at least two points"]
        }
      }
    )
  end

  it "returns a validation error for an unsupported profile" do
    post "/route", params: valid_params.merge(profile: "train"), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to eq(
      "error" => {
        "code" => "validation_error",
        "message" => "Request validation failed",
        "details" => {
          "profile" => ["is not included in the list"]
        }
      }
    )
  end

  it "returns a validation error when options is not an object" do
    post "/route", params: valid_params.merge(options: "invalid"), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)).to eq(
      "error" => {
        "code" => "validation_error",
        "message" => "Request validation failed",
        "details" => {
          "options" => ["must be an object"]
        }
      }
    )
  end

  it "returns an upstream timeout envelope" do
    allow(RoutingService).to receive(:new).and_raise(UpstreamTimeoutError.new(provider: "graphhopper"))

    post "/route", params: valid_params, as: :json

    expect(response).to have_http_status(:gateway_timeout)
    expect(JSON.parse(response.body)).to eq(
      "error" => {
        "code" => "upstream_timeout",
        "message" => "Routing provider timed out",
        "details" => {
          "provider" => "graphhopper"
        }
      }
    )
  end

  it "returns an upstream error envelope" do
    allow(RoutingService).to receive(:new).and_raise(
      UpstreamError.new(
        message: "Routing provider returned an error",
        details: { provider: "graphhopper", status: 400 }
      )
    )

    post "/route", params: valid_params, as: :json

    expect(response).to have_http_status(:bad_gateway)
    expect(JSON.parse(response.body)).to eq(
      "error" => {
        "code" => "upstream_error",
        "message" => "Routing provider returned an error",
        "details" => {
          "provider" => "graphhopper",
          "status" => 400
        }
      }
    )
  end
end