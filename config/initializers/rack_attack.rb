# rack_attack.rb - Demo purposes only: settings are deliberately strict for public access
#
# NOTE:
# This rack-attack configuration is tuned for a demo site under these assumptions:
# - Single application instance (no multi-node rate limit synchronization required)
# - Very low traffic and mostly known visitors
# - Aggressive blocking is acceptable for suspicious behavior
# - Client source IP is correctly forwarded by the reverse proxy to this app

# Uncomment the following lines to always allow requests from localhost.
# All blocklists and throttles will be skipped for localhost requests.
#Rack::Attack.safelist('allow from localhost') do |req|
#  '127.0.0.1' == req.ip || '::1' == req.ip
#end

rack_attack_config = Module.new do
  module_function

  def env_boolean(name, default)
    value = ENV.key?(name) ? ENV[name] : default
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def env_positive_integer(name, default)
    value = ENV.fetch(name, default.to_s)
    integer = Integer(value, 10)
    integer.positive? ? integer : default
  rescue ArgumentError, TypeError
    default
  end

  def probe_exact_paths
    [
      '/.env',
      '/.git/config',
      '/.DS_Store',
      '/.aws/credentials',
      '/server-status',
      '/v2/_catalog',
      '/___proxy_subdomain_cpanel',
      '/___proxy_subdomain_whm/login',
      '/wp-login.php',
      '/phpmyadmin',
      '/graphql',
      '/api',
      '/api/graphql',
      '/graphql/api',
      '/api/gql'
    ].freeze
  end

  def probe_prefixes
    [
      '/.git/',
      '/.svn/',
      '/.aws/',
      '/ecp/'
    ].freeze
  end

  def probe_patterns
    [
      %r{\A/\.env(?:\.[^/?#]+)?\z}i,
      %r{\A/(?:api/)?(?:graphql|gql)(?:/api)?\z}i
    ].freeze
  end

  def probe_path?(path)
    probe_exact_paths.include?(path) ||
      probe_prefixes.any? { |prefix| path.start_with?(prefix) } ||
      probe_patterns.any? { |pattern| path.match?(pattern) }
  end

  def throttled_path_exclusions
    ['/up'].freeze
  end

  def ban_cache_key(ip)
    "rack:attack:ban:#{ip}"
  end

  def settings
    {
      enabled: env_boolean('ENABLED_RACK_ATTACK', '1'),
      get_throttle_name: 'req/ip:get',
      write_throttle_name: 'req/ip:write',
      get_throttle_limit: env_positive_integer('RACK_ATTACK_GET_THROTTLE_LIMIT', 30),
      write_throttle_limit: env_positive_integer('RACK_ATTACK_WRITE_THROTTLE_LIMIT', 5),
      throttle_period: env_positive_integer('RACK_ATTACK_THROTTLE_PERIOD_SECONDS', 60).seconds,
      ban_duration: env_positive_integer('RACK_ATTACK_BAN_DURATION_SECONDS', 1*60*60).seconds,
      throttled_path_exclusions: throttled_path_exclusions
    }
  end
end

rack_attack_settings = rack_attack_config.settings

Rack::Attack.enabled = rack_attack_settings[:enabled]
Rack::Attack.cache.store = Rails.cache

if rack_attack_settings[:enabled]
  # Block IPs that hit known scanner probe paths (immediate ban and cache)
  Rack::Attack.blocklist('block probe path scanners') do |req|
    if rack_attack_config.probe_path?(req.path)
      Rack::Attack.cache.store.write(
        rack_attack_config.ban_cache_key(req.ip),
        '1',
        expires_in: rack_attack_settings[:ban_duration]
      )
      true
    else
      false
    end
  end

  Rack::Attack.throttle(
    rack_attack_settings[:get_throttle_name],
    limit: rack_attack_settings[:get_throttle_limit],
    period: rack_attack_settings[:throttle_period]
  ) do |req|
    req.ip if (req.get? || req.head?) && !rack_attack_settings[:throttled_path_exclusions].include?(req.path)
  end

  Rack::Attack.throttle(
    rack_attack_settings[:write_throttle_name],
    limit: rack_attack_settings[:write_throttle_limit],
    period: rack_attack_settings[:throttle_period]
  ) do |req|
    req.ip unless req.get? || req.head?
  end

  Rack::Attack.blocklist('ban abusive IPs') do |req|
    Rack::Attack.cache.store.read(rack_attack_config.ban_cache_key(req.ip)) == '1'
  end

  Rack::Attack.throttled_responder = lambda do |_request|
    headers = {
      'Content-Type' => 'application/json; charset=utf-8',
      'Retry-After' => rack_attack_settings[:throttle_period].to_i.to_s
    }

    body = {
      error: 'throttled',
      message: 'Rate limit exceeded, retry after some time'
    }.to_json

    [429, headers, [body]]
  end

  Rack::Attack.blocklisted_responder = lambda do |_request|
    headers = {
      'Content-Type' => 'application/json; charset=utf-8',
      'Retry-After' => rack_attack_settings[:ban_duration].to_i.to_s
    }

    body = {
      error: 'forbidden',
      message: 'Access denied due to suspicious activity'
    }.to_json

    [403, headers, [body]]
  end

end
