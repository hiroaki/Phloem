class RouteRequest
  include ActiveModel::Model

  attr_reader :profile, :points, :options

  validates :profile, presence: true
  validate :profile_is_supported
  validate :points_are_valid
  validate :options_are_valid

  def initialize(attributes = {})
    payload = attributes.to_h.deep_symbolize_keys

    @profile = payload[:profile]
    @points = payload[:points]
    @options = payload.key?(:options) ? payload[:options] : {}
  end

  def to_h
    {
      profile: profile,
      points: normalized_points,
      options: options || {}
    }
  end

  def error_details
    errors.to_hash
  end

  private

  def profile_is_supported
    return if profile.blank?

    available_profiles = RouteProfileCatalog.available_profiles
    if available_profiles.empty?
      errors.add(:profile, "no profiles are currently available")
      return
    end

    return if available_profiles.include?(profile.to_s)

    errors.add(:profile, "is not included in the list")
  end

  def points_are_valid
    unless points.is_a?(Array) && points.size >= 2
      errors.add(:points, "must contain at least two points")
      return
    end

    points.each_with_index do |point, index|
      point_hash = point.respond_to?(:to_h) ? point.to_h.symbolize_keys : nil

      unless point_hash.is_a?(Hash)
        errors.add(:points, "point #{index} must be an object with lat and lon")
        next
      end

      lat = parse_coordinate(point_hash[:lat])
      lon = parse_coordinate(point_hash[:lon])

      errors.add(:points, "point #{index} is missing a valid lat") if lat.nil?
      errors.add(:points, "point #{index} is missing a valid lon") if lon.nil?
      errors.add(:points, "point #{index} lat must be between -90 and 90") if lat && !lat.between?(-90.0, 90.0)
      errors.add(:points, "point #{index} lon must be between -180 and 180") if lon && !lon.between?(-180.0, 180.0)
    end
  end

  def options_are_valid
    return if options.is_a?(Hash)

    errors.add(:options, "must be an object")
  end

  def normalized_points
    Array(points).map do |point|
      point_hash = point.to_h.symbolize_keys

      {
        lat: Float(point_hash[:lat]),
        lon: Float(point_hash[:lon])
      }
    end
  end

  def parse_coordinate(value)
    Float(value)
  rescue ArgumentError, TypeError
    nil
  end
end