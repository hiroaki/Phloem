require "json"
require "net/http"

class GraphHopperAdapter < RoutingProvider
  PROVIDER_NAME = "graphhopper".freeze

  def initialize(
    base_url: ENV.fetch("GRAPH_HOPPER_BASE_URL", "http://localhost:8989"),
    api_key: ENV["GRAPH_HOPPER_API_KEY"],
    timeout: ENV.fetch("GRAPH_HOPPER_TIMEOUT_SECONDS", "5").to_f
  )
    @base_url = base_url
    @api_key = api_key
    @timeout = timeout
  end

  def route(profile:, points:, options: {})
    response = perform_request(route_uri, route_body(profile:, points:, options:))
    payload = parse_json(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise UpstreamError.new(
        message: payload["message"] || "Routing provider returned an error",
        details: {
          provider: PROVIDER_NAME,
          status: response.code.to_i,
          body: payload
        }
      )
    end

    path = payload.fetch("paths", []).first
    geometry = path&.dig("points")

    unless geometry.is_a?(Hash) && geometry["type"] == "LineString" && geometry["coordinates"].is_a?(Array)
      raise UpstreamError.new(
        message: "Routing provider returned an unexpected response",
        details: {
          provider: PROVIDER_NAME,
          status: response.code.to_i,
          body: payload
        }
      )
    end

    {
      provider: PROVIDER_NAME,
      geometry: geometry,
      distance_meters: path.fetch("distance").to_f,
      duration_seconds: path.fetch("time").to_f / 1000.0,
      warnings: extract_warnings(payload)
    }
  rescue Timeout::Error, Errno::ETIMEDOUT
    raise UpstreamTimeoutError.new(provider: PROVIDER_NAME)
  rescue JSON::ParserError, KeyError, NoMethodError
    raise UpstreamError.new(
      message: "Routing provider returned an unexpected response",
      details: { provider: PROVIDER_NAME }
    )
  end

  private

  def route_body(profile:, points:, options: {})
    {
      profile: profile,
      points: points.map { |point| [point.fetch(:lon), point.fetch(:lat)] },
      instructions: false,
      calc_points: true,
      points_encoded: false
    }.merge(translated_options(options))
  end

  def translated_options(options)
    translated = {}
    translated[:locale] = options[:locale] if options.is_a?(Hash) && options[:locale].is_a?(String)
    translated
  end

  def route_uri
    uri = URI.parse(@base_url)
    path_parts = [uri.path, "route"].map { |part| part.to_s.gsub(%r{\A/|/\z}, "") }.reject(&:empty?)
    uri.path = "/#{path_parts.join('/')}"

    query = uri.query ? URI.decode_www_form(uri.query) : []
    query << ["key", @api_key] unless @api_key.to_s.empty?
    uri.query = query.empty? ? nil : URI.encode_www_form(query)
    uri
  end

  def perform_request(uri, body)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.dump(body)

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: @timeout,
      read_timeout: @timeout,
      write_timeout: @timeout
    ) do |http|
      http.request(request)
    end
  rescue SocketError, EOFError, IOError, SystemCallError => error
    raise UpstreamError.new(
      message: "Routing provider request failed",
      details: {
        provider: PROVIDER_NAME,
        cause: error.class.name
      }
    )
  end

  def parse_json(body)
    return {} if body.to_s.empty?

    JSON.parse(body)
  end

  def extract_warnings(payload)
    Array(payload["hints"]).filter_map do |hint|
      next unless hint.is_a?(Hash)

      hint["message"] || hint["details"]
    end
  end
end